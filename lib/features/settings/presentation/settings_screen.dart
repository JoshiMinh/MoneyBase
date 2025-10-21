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

  Future<void> _copyUserIdToClipboard(BuildContext context, String userId) async {
    await Clipboard.setData(ClipboardData(text: userId));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account ID copied to clipboard.')),
    );
  }

  Future<void> _copySupportEmail(BuildContext context) async {
    const supportEmail = 'support@moneybase.app';
    await Clipboard.setData(const ClipboardData(text: supportEmail));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support email copied to clipboard.')),
    );
  }

  void _showAboutMoneyBase() {
    showAboutDialog(
      context: context,
      applicationName: 'MoneyBase',
      applicationVersion: 'Web preview',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/icon.png',
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      ),
      applicationLegalese: 'Crafted for the MoneyBase budgeting suite.',
    );
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

        final quickStats = <Widget>[
          _QuickStatPill(
            icon:
                _remindersEnabled ? Icons.notifications_active : Icons.notifications_off_outlined,
            label: 'Reminders',
            value:
                _remindersEnabled ? 'Daily at $reminderLabel' : 'Disabled on web',
            accent: colors.secondaryAccent,
          ),
          _QuickStatPill(
            icon: controller.darkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_outlined,
            label: 'Theme',
            value: controller.darkMode ? 'Dark mode' : 'Light mode',
            accent: colors.primaryAccent,
          ),
        ];
        if (user != null) {
          quickStats.add(
            const _QuickStatPill(
              icon: Icons.cloud_done_outlined,
              label: 'Sync',
              value: 'Cloud backup active',
              accent: MoneyBaseColors.blue,
            ),
          );
        }

        final headerActions = <Widget>[];
        if (widget.onLogout != null && user != null) {
          headerActions.add(
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          );
        }

        final heroPanel = MoneyBaseFrostedPanel(
          padding: EdgeInsets.symmetric(
            horizontal: layout.isWide ? 40 : 28,
            vertical: layout.isWide ? 36 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile overview',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              profileHeader,
              if (quickStats.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: quickStats,
                ),
              ],
              if (headerActions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: headerActions,
                ),
              ],
            ],
          ),
        );

        final preferencesPanel = MoneyBaseFrostedPanel(
          padding: EdgeInsets.symmetric(
            horizontal: layout.isWide ? 32 : 24,
            vertical: layout.isWide ? 32 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SettingsSectionHeader(
                icon: Icons.tune_rounded,
                title: 'Personal preferences',
                subtitle:
                    'Tailor reminders and appearance so the web experience mirrors Android.',
              ),
              const SizedBox(height: 24),
              _SettingsToggleTile(
                title: 'Expense reminder',
                subtitle:
                    'Keep the nightly spend nudge aligned across every MoneyBase surface.',
                value: _remindersEnabled,
                onChanged: (value) => setState(() => _remindersEnabled = value),
                footer: Row(
                  children: [
                    Text(
                      'Reminder time',
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed:
                          _remindersEnabled ? () => _pickReminderTime(context) : null,
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
                        disabledBackgroundColor:
                            colors.surfaceBorder.withOpacity(0.2),
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
                title: 'Dark mode',
                subtitle:
                    'Switch to MoneyBase\'s amethyst dark finish instantly.',
                value: controller.darkMode,
                onChanged: controller.setDarkMode,
              ),
            ],
          ),
        );

        final bool signedIn = user != null;
        final dataToolsPanel = MoneyBaseFrostedPanel(
          padding: EdgeInsets.symmetric(
            horizontal: layout.isWide ? 32 : 24,
            vertical: layout.isWide ? 32 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingsSectionHeader(
                icon: Icons.table_view_outlined,
                title: 'Data tools & CSV',
                subtitle: signedIn
                    ? 'Export a backup or paste in CSV rows to migrate data between installs.'
                    : 'Sign in to unlock CSV exports and imports for your transactions.',
              ),
              if (!signedIn) ...[
                const SizedBox(height: 16),
                const _SettingsHintBanner(
                  message: 'CSV workflows become available once you sign in.',
                ),
              ],
              const SizedBox(height: 24),
              _DataActionTile(
                icon: Icons.download_outlined,
                title: 'Export transactions to CSV',
                subtitle:
                    'Download your latest transactions so you can archive a snapshot.',
                buttonLabel: 'Export CSV',
                onPressed: signedIn && !_isExportingCsv
                    ? () => _exportTransactionsCsv(context, user!.uid)
                    : null,
                loading: signedIn && _isExportingCsv,
              ),
              const SizedBox(height: 16),
              _DataActionTile(
                icon: Icons.upload_file_outlined,
                title: 'Import transactions from CSV',
                subtitle:
                    'Paste CSV rows exported from MoneyBase or another budgeting tool to bulk add entries.',
                buttonLabel: 'Import CSV',
                onPressed: signedIn && !_isImportingCsv
                    ? () => _importTransactionsCsv(context, user!.uid)
                    : null,
                loading: signedIn && _isImportingCsv,
              ),
            ],
          ),
        );

        final supportPanel = MoneyBaseFrostedPanel(
          padding: EdgeInsets.symmetric(
            horizontal: layout.isWide ? 32 : 24,
            vertical: layout.isWide ? 32 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SettingsSectionHeader(
                icon: Icons.support_agent_outlined,
                title: 'Support & extras',
                subtitle: 'Get help and learn more about the MoneyBase experience.',
              ),
              const SizedBox(height: 24),
              _SupportActionTile(
                icon: Icons.email_outlined,
                title: 'Contact support',
                subtitle: 'Copy support@moneybase.app and share details with the team.',
                onTap: () => _copySupportEmail(context),
              ),
              const SizedBox(height: 12),
              _SupportActionTile(
                icon: Icons.info_outline,
                title: 'About MoneyBase',
                subtitle: 'Review the project story and licences.',
                onTap: _showAboutMoneyBase,
              ),
              if (user != null) ...[
                const SizedBox(height: 12),
                _SupportActionTile(
                  icon: Icons.copy_all_outlined,
                  title: 'Copy account ID',
                  subtitle: 'Share this identifier when contacting support about sync issues.',
                  onTap: () => _copyUserIdToClipboard(context, user.uid),
                ),
              ],
            ],
          ),
        );

        final sectionSpacing = layout.isWide ? 28.0 : 24.0;

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
              'Personalise MoneyBase on the web so it mirrors the Android build.',
              style: textTheme.bodyLarge?.copyWith(color: colors.mutedText),
            ),
            const SizedBox(height: 32),
            heroPanel,
            SizedBox(height: sectionSpacing),
            preferencesPanel,
            SizedBox(height: sectionSpacing),
            dataToolsPanel,
            SizedBox(height: sectionSpacing),
            supportPanel,
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
            Image.asset('assets/icon.png', fit: BoxFit.cover),
      );
    } else {
      avatar = Image.asset('assets/icon.png', fit: BoxFit.cover);
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final accent = colors.primaryAccent;
    final isDisabled = onPressed == null;
    final effectiveOnPressed = (loading || onPressed == null) ? null : onPressed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceBackground.withOpacity(0.9),
            colors.surfaceBackground.withOpacity(0.72),
          ],
        ),
        border: Border.all(color: accent.withOpacity(isDisabled ? 0.18 : 0.32)),
        boxShadow: [
          BoxShadow(
            color: colors.surfaceShadow,
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.16),
              border: Border.all(color: accent.withOpacity(0.32)),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 18),
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
                  style: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          FilledButton(
            onPressed: effectiveOnPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              backgroundColor: accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: colors.surfaceBorder.withOpacity(0.6),
              disabledForegroundColor: colors.mutedText,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: loading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(buttonLabel),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_outward_rounded, size: 18),
                      ],
                    ),
            ),
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final accent = colors.secondaryAccent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: value
              ? [
                  accent.withOpacity(0.28),
                  accent.withOpacity(0.12),
                ]
              : [
                  colors.surfaceBackground.withOpacity(0.88),
                  colors.surfaceBackground.withOpacity(0.72),
                ],
        ),
        border: Border.all(
          color: value
              ? accent.withOpacity(0.45)
              : colors.surfaceBorder.withOpacity(0.8),
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ]
            : [
                BoxShadow(
                  color: colors.surfaceShadow,
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
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
                trackColor: MaterialStateProperty.resolveWith<Color?>(
                  (states) => states.contains(MaterialState.selected)
                      ? accent.withOpacity(0.35)
                      : colors.surfaceBorder.withOpacity(0.6),
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: footer == null
                ? const SizedBox.shrink()
                : Padding(
                    key: const ValueKey('footer'),
                    padding: const EdgeInsets.only(top: 18),
                    child: footer,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primaryAccent.withOpacity(0.32),
                colors.secondaryAccent.withOpacity(0.18),
              ],
            ),
            border: Border.all(color: colors.primaryAccent.withOpacity(0.4)),
          ),
          child: Icon(icon, color: colors.primaryAccent),
        ),
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
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickStatPill extends StatelessWidget {
  const _QuickStatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final textTheme = Theme.of(context).textTheme;
    final resolvedAccent = accent ?? colors.primaryAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            resolvedAccent.withOpacity(0.26),
            resolvedAccent.withOpacity(0.12),
          ],
        ),
        border: Border.all(color: resolvedAccent.withOpacity(0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: resolvedAccent, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupportActionTile extends StatelessWidget {
  const _SupportActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: colors.surfaceBackground.withOpacity(0.6),
                  border: Border.all(color: colors.surfaceBorder.withOpacity(0.8)),
                ),
                child: Icon(icon, color: colors.primaryAccent),
              ),
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHintBanner extends StatelessWidget {
  const _SettingsHintBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.surfaceBackground.withOpacity(0.72),
        border: Border.all(color: colors.surfaceBorder.withOpacity(0.9)),
      ),
      child: Text(
        message,
        style: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
      ),
    );
  }
}
