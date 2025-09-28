import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/theme.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/google_sign_in_service.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/utils/csv_utils.dart';
import '../../../core/utils/csv_exporter.dart';
import '../../common/presentation/moneybase_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 17, minute: 25);
  late final TransactionRepository _transactionRepository;
  bool _isExportingCsv = false;
  bool _isImportingCsv = false;

  @override
  void initState() {
    super.initState();
    _transactionRepository = TransactionRepository();
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final result = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (result != null) {
      setState(() => _reminderTime = result);
    }
  }

  String _resolveDisplayName(User user, String? displayName) {
    final trimmed = displayName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'MoneyBase user';
  }

  Future<void> _exportTransactionsCsv(
    BuildContext context,
    String userId,
  ) async {
    if (_isExportingCsv) {
      return;
    }

    setState(() => _isExportingCsv = true);
    try {
      final transactions = await _transactionRepository.fetchAllTransactions(
        userId,
      );
      if (transactions.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to export yet.')),
        );
        return;
      }

      final csv = encodeTransactionsCsv(transactions);
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final fileName = 'moneybase-transactions-$timestamp';
      final exportLocation = await saveCsvExport(fileName: fileName, csv: csv);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${transactions.length} transactions to '
            '${exportLocation ?? '$fileName.csv'}.',
          ),
        ),
      );

      await showDialog<void>(
        context: context,
        builder: (context) => _CsvPreviewDialog(
          csv: csv,
          locationDescription: exportLocation ?? '$fileName.csv',
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export CSV: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingCsv = false);
      }
    }
  }

  Future<void> _importTransactionsCsv(
    BuildContext context,
    String userId,
  ) async {
    if (_isImportingCsv) {
      return;
    }

    final csvInput = await showDialog<String>(
      context: context,
      builder: (context) => const _CsvPasteDialog(),
    );

    final trimmed = csvInput?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }

    setState(() => _isImportingCsv = true);
    try {
      final transactions = decodeTransactionsCsv(trimmed);
      if (transactions.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No valid transactions were found in the provided CSV.',
            ),
          ),
        );
        return;
      }

      await _transactionRepository.importTransactions(userId, transactions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${transactions.length} transactions from CSV.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to import CSV: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isImportingCsv = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ThemeControllerProvider.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = context.moneyBaseColors;
    final reminderLabel = _reminderTime.format(context);
    final user = FirebaseAuth.instance.currentUser;

    return MoneyBaseScaffold(
      maxContentWidth: 960,
      widePadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
      builder: (context, layout) {
        final Widget profileHeader;
        if (user == null) {
          profileHeader = _ProfileHeader(
            textTheme: textTheme,
            displayName: 'Guest',
            email: 'Sign in to see your synced profile.',
          );
        } else {
          final userDocStream = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots();
          profileHeader = StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userDocStream,
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final displayName =
                  (data?['displayName'] as String?)?.trim() ?? user.displayName;
              final email =
                  (data?['email'] as String?) ?? user.email ?? 'Unknown user';
              final photoUrl =
                  (data?['profilePictureUrl'] as String?) ??
                  (data?['photoUrl'] as String?) ??
                  user.photoURL;
              final loading =
                  snapshot.connectionState == ConnectionState.waiting &&
                  data == null;

              return _ProfileHeader(
                textTheme: textTheme,
                displayName: _resolveDisplayName(user, displayName),
                email: email,
                photoUrl: photoUrl,
                loading: loading,
              );
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: textTheme.headlineMedium?.copyWith(
                color: colors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personalise reminders to mirror the Android build across web.',
              style: textTheme.bodyLarge?.copyWith(color: colors.mutedText),
            ),
            const SizedBox(height: 32),
            MoneyBaseFrostedPanel(
              padding: EdgeInsets.symmetric(
                horizontal: layout.isWide ? 36 : 28,
                vertical: layout.isWide ? 36 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileHeader,
                  const SizedBox(height: 32),
                  _SettingsToggleTile(
                    title: 'Expense Reminder',
                    subtitle:
                        'Keep the nightly spend nudge in sync across MoneyBase surfaces.',
                    value: _remindersEnabled,
                    onChanged: (value) =>
                        setState(() => _remindersEnabled = value),
                    footer: Row(
                      children: [
                        Text(
                          'Reminder Time',
                          style: textTheme.titleSmall?.copyWith(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _remindersEnabled
                              ? () => _pickReminderTime(context)
                              : null,
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(reminderLabel),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            foregroundColor: colors.primaryText,
                            disabledForegroundColor: colors.mutedText,
                            backgroundColor: _remindersEnabled
                                ? colors.secondaryAccent.withOpacity(0.16)
                                : colors.surfaceBorder.withOpacity(0.4),
                            disabledBackgroundColor: colors.surfaceBorder
                                .withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SettingsToggleTile(
                    title: 'Dark Mode',
                    subtitle:
                        'Match Android\'s amethyst dark finish instantly.',
                    value: controller.darkMode,
                    onChanged: controller.setDarkMode,
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      if (widget.onLogout != null)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            backgroundColor: MoneyBaseColors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            await googleSignInService.signOut();
                            widget.onLogout?.call();
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Log out'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (user != null) ...[
              const SizedBox(height: 24),
              MoneyBaseFrostedPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data tools',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Export a backup or paste in CSV rows to migrate data between MoneyBase installs.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _DataActionTile(
                      icon: Icons.download_outlined,
                      title: 'Export transactions to CSV',
                      subtitle:
                          'Exports your latest transactions so you can download a CSV snapshot.',
                      buttonLabel: 'Export CSV',
                      onPressed: _isExportingCsv
                          ? null
                          : () => _exportTransactionsCsv(context, user.uid),
                      loading: _isExportingCsv,
                    ),
                    const SizedBox(height: 16),
                    _DataActionTile(
                      icon: Icons.upload_file_outlined,
                      title: 'Import transactions from CSV',
                      subtitle:
                          'Paste CSV rows exported from MoneyBase or another budgeting tool to bulk add entries.',
                      buttonLabel: 'Import CSV',
                      onPressed: _isImportingCsv
                          ? null
                          : () => _importTransactionsCsv(context, user.uid),
                      loading: _isImportingCsv,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.textTheme,
    this.displayName,
    this.email,
    this.photoUrl,
    this.loading = false,
  });

  final TextTheme textTheme;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final resolvedName = (displayName != null && displayName!.trim().isNotEmpty)
        ? displayName!
        : 'MoneyBase user';
    final resolvedEmail = (email != null && email!.trim().isNotEmpty)
        ? email!
        : 'No email available';

    Widget avatar;
    if (loading) {
      avatar = Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: colors.primaryAccent,
          ),
        ),
      );
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('app_icon.ico', fit: BoxFit.cover),
      );
    } else {
      avatar = Image.asset('app_icon.ico', fit: BoxFit.cover);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: const [MoneyBaseColors.blue, MoneyBaseColors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: colors.primaryAccent.withOpacity(0.24),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: SizedBox(width: 68, height: 68, child: avatar),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolvedName,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                loading && (email == null || email!.isEmpty)
                    ? 'Syncing profile details…'
                    : resolvedEmail,
                style: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DataActionTile extends StatelessWidget {
  const _DataActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    required this.loading,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDisabled = onPressed == null;
    final colors = context.moneyBaseColors;
    final accent = colors.primaryAccent;

    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(color: colors.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              backgroundColor: (loading || !isDisabled)
                  ? accent
                  : colors.surfaceBorder.withOpacity(0.6),
              foregroundColor: (loading || !isDisabled)
                  ? Colors.white
                  : colors.mutedText,
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _CsvPreviewDialog extends StatelessWidget {
  const _CsvPreviewDialog({
    required this.csv,
    required this.locationDescription,
  });

  final String csv;
  final String locationDescription;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.moneyBaseColors;

    return AlertDialog(
      title: const Text('CSV export ready'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your CSV export has been saved to $locationDescription. Copy the contents below or close this dialog to continue.',
              style: textTheme.bodyMedium?.copyWith(color: colors.primaryText),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.surfaceBorder),
              ),
              constraints: const BoxConstraints(maxHeight: 240),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: SelectableText(
                  csv,
                  style: textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colors.primaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: csv)),
          child: const Text('Copy to clipboard'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _CsvPasteDialog extends StatefulWidget {
  const _CsvPasteDialog();

  @override
  State<_CsvPasteDialog> createState() => _CsvPasteDialogState();
}

class _CsvPasteDialogState extends State<_CsvPasteDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Paste at least one CSV row.');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Import CSV transactions'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste CSV rows exported from MoneyBase or a compatible template. The importer keeps the CSV text on this device only.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 12,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText:
                    'id,date,description,amount,currencyCode,isIncome,categoryId,walletId,createdAt',
                errorText: _errorText,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Import')),
      ],
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.footer,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.moneyBaseColors;
    final accent = colors.secondaryAccent;

    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: accent,
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 18), footer!],
        ],
      ),
    );
  }
}
