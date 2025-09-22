import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/palettes.dart';
import '../../../app/theme/theme.dart';
import '../../../core/constants/icon_library.dart';
import '../../../core/models/category.dart';
import '../../../core/models/wallet.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/repositories/wallet_repository.dart';
import '../../../core/services/google_sign_in_service.dart';
import '../../../core/utils/color_utils.dart';
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
  late final WalletRepository _walletRepository;
  late final CategoryRepository _categoryRepository;

  @override
  void initState() {
    super.initState();
    _walletRepository = WalletRepository();
    _categoryRepository = CategoryRepository();
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

  @override
  Widget build(BuildContext context) {
    final controller = ThemeControllerProvider.of(context);
    final textTheme = Theme.of(context).textTheme;
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
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personalise reminders and theming to mirror the Android build across web.',
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
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
                            color: Colors.white.withOpacity(0.84),
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
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white.withOpacity(
                              0.4,
                            ),
                            backgroundColor: _remindersEnabled
                                ? Colors.white.withOpacity(0.12)
                                : Colors.white.withOpacity(0.06),
                            disabledBackgroundColor: Colors.white.withOpacity(
                              0.04,
                            ),
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
                  const SizedBox(height: 28),
                  Text(
                    'Select Color Scheme',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (var i = 0; i < kMoneyBasePalettes.length; i++)
                        _PaletteOption(
                          color: kMoneyBasePalettes[i].primary,
                          selected: controller.palette == kMoneyBasePalettes[i],
                          onTap: () {
                            controller.updateCustomPrimary(null);
                            controller.selectPalette(i);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          backgroundColor: Colors.white.withOpacity(0.12),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Export Transactions to CSV'),
                      ),
                      if (widget.onLogout != null)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            backgroundColor: const Color(0xFFE54C4C),
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
              _DataManagementPanel(
                userId: user.uid,
                walletRepository: _walletRepository,
                categoryRepository: _categoryRepository,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DataManagementPanel extends StatelessWidget {
  const _DataManagementPanel({
    required this.userId,
    required this.walletRepository,
    required this.categoryRepository,
  });

  final String userId;
  final WalletRepository walletRepository;
  final CategoryRepository categoryRepository;

  @override
  Widget build(BuildContext context) {
    return MoneyBaseFrostedPanel(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WalletSection(
            userId: userId,
            repository: walletRepository,
          ),
          const SizedBox(height: 32),
          _CategorySection(
            userId: userId,
            repository: categoryRepository,
          ),
        ],
      ),
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
    final resolvedName = (displayName != null && displayName!.trim().isNotEmpty)
        ? displayName!
        : 'MoneyBase user';
    final resolvedEmail = (email != null && email!.trim().isNotEmpty)
        ? email!
        : 'No email available';

    Widget avatar;
    if (loading) {
      avatar = const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Colors.white,
          ),
        ),
      );
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('web/favicon.png', fit: BoxFit.cover),
      );
    } else {
      avatar = Image.asset('web/favicon.png', fit: BoxFit.cover);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF5D9BFF), Color(0xFF7B5BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 2),
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
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                loading && (email == null || email!.isEmpty)
                    ? 'Syncing profile details…'
                    : resolvedEmail,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _walletTypeLabel(WalletType type) {
  switch (type) {
    case WalletType.physical:
      return 'Physical';
    case WalletType.bankAccount:
      return 'Bank account';
    case WalletType.crypto:
      return 'Crypto';
    case WalletType.investment:
      return 'Investment';
    case WalletType.other:
      return 'Other';
  }
}

class _WalletSection extends StatelessWidget {
  const _WalletSection({required this.userId, required this.repository});

  final String userId;
  final WalletRepository repository;

  Future<void> _showWalletDialog(BuildContext context, {Wallet? wallet}) async {
    final result = await showDialog<Wallet>(
      context: context,
      builder: (context) => _WalletDialog(initial: wallet),
    );

    if (result == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      if (wallet == null) {
        await repository.addWallet(userId, result);
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Wallet added successfully.')),
        );
      } else {
        await repository.updateWallet(userId, result);
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Wallet updated successfully.')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save wallet: $error')),
      );
    }
  }

  Future<void> _confirmDeleteWallet(BuildContext context, Wallet wallet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete wallet?'),
        content: Text(
          'This will remove "${wallet.name.isEmpty ? 'Untitled wallet' : wallet.name}" and any linked balances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE54C4C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      await repository.deleteWallet(userId, wallet.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Wallet removed.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete wallet: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Wallets',
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showWalletDialog(context),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Add wallet'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Wallet>>(
          stream: repository.watchWallets(userId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorNotice(message: 'Unable to load wallets: ${snapshot.error}');
            }

            final wallets = snapshot.data ?? const <Wallet>[];
            final loading =
                snapshot.connectionState == ConnectionState.waiting && wallets.isEmpty;

            if (loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (wallets.isEmpty) {
              return const _EmptyNotice(
                message: 'No wallets yet. Add one to begin tracking balances.',
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wallets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                final title = wallet.name.isNotEmpty ? wallet.name : 'Untitled wallet';
                final typeDescription = _walletTypeLabel(wallet.type);
                final currency = wallet.currencyCode.isEmpty
                    ? 'Currency not set'
                    : wallet.currencyCode.toUpperCase();
                final iconData = IconLibrary.iconForWallet(wallet.iconName);
                final accent = parseHexColor(wallet.color);

                return _SettingsListTile(
                  title: title,
                  metadata: [
                    '$typeDescription • $currency',
                    if (wallet.balance != 0)
                      'Balance: ${wallet.balance.toStringAsFixed(2)}',
                  ],
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: accent?.withOpacity(0.2) ??
                        Colors.white.withOpacity(0.08),
                    child: Icon(iconData, color: accent ?? Colors.white),
                  ),
                  onEdit: () => _showWalletDialog(context, wallet: wallet),
                  onDelete: () => _confirmDeleteWallet(context, wallet),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.userId, required this.repository});

  final String userId;
  final CategoryRepository repository;

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'This will remove "${category.name.isEmpty ? 'Untitled category' : category.name}" from your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE54C4C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      await repository.deleteCategory(userId, category.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Category removed.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete category: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<Category>>(
      stream: repository.watchCategories(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Categories',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ErrorNotice(
                message: 'Unable to load categories: ${snapshot.error}',
              ),
            ],
          );
        }

        final categories = snapshot.data ?? const <Category>[];
        final loading =
            snapshot.connectionState == ConnectionState.waiting && categories.isEmpty;

        Future<void> openDialog({Category? category}) {
          return _openCategoryDialog(
            context,
            categories: categories,
            category: category,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Categories',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => openDialog(),
                  icon: const Icon(Icons.category_outlined),
                  label: const Text('Add category'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (categories.isEmpty)
              const _EmptyNotice(
                message: 'No categories yet. Create one to organise transactions.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final title =
                      category.name.isNotEmpty ? category.name : 'Untitled category';
                  final parent = categories.firstWhere(
                    (item) =>
                        category.parentCategoryId != null &&
                        category.parentCategoryId!.isNotEmpty &&
                        item.id == category.parentCategoryId,
                    orElse: () => const Category(),
                  );

                  final metadata = <String>[
                    if (category.color.isNotEmpty)
                      'Color: ${category.color.toUpperCase()}',
                    if (category.parentCategoryId != null &&
                        category.parentCategoryId!.isNotEmpty)
                      'Parent: ${parent.name.isNotEmpty ? parent.name : category.parentCategoryId}',
                  ];

                  final iconData = IconLibrary.iconForCategory(category.iconName);
                  final accent = parseHexColor(category.color);

                  return _SettingsListTile(
                    title: title,
                    metadata: metadata,
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          accent?.withOpacity(0.2) ?? Colors.white.withOpacity(0.08),
                      child: Icon(iconData, color: accent ?? Colors.white),
                    ),
                    onEdit: () => openDialog(category: category),
                    onDelete: () => _confirmDeleteCategory(context, category),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _openCategoryDialog(
    BuildContext context, {
    required List<Category> categories,
    Category? category,
  }) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => _CategoryDialog(
        initial: category,
        categories: categories,
      ),
    );

    if (result == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      if (category == null) {
        await repository.addCategory(userId, result);
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Category added successfully.')),
        );
      } else {
        await repository.updateCategory(userId, result);
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Category updated successfully.')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save category: $error')),
      );
    }
  }
}

class _SettingsListTile extends StatelessWidget {
  const _SettingsListTile({
    required this.title,
    required this.metadata,
    required this.onEdit,
    required this.onDelete,
    this.leading,
  });

  final String title;
  final List<String> metadata;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                for (final entry in metadata)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      entry,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.72),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconChooser extends StatelessWidget {
  const _IconChooser({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final Iterable<MapEntry<String, IconData>> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectedLabel = selected.replaceAll('_', ' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selectedLabel,
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in options)
              _IconChoice(
                name: entry.key,
                icon: entry.value,
                selected: entry.key == selected,
                onTap: () => onSelected(entry.key),
              ),
          ],
        ),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = selected
        ? Colors.white.withOpacity(0.24)
        : Colors.white.withOpacity(0.08);
    final borderColor = selected
        ? colorScheme.primary
        : Colors.white.withOpacity(0.16);

    return Tooltip(
      message: name.replaceAll('_', ' '),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            color: background,
          ),
          child: Icon(
            icon,
            color: selected ? colorScheme.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        message,
        style: textTheme.bodyMedium?.copyWith(
          color: Colors.white.withOpacity(0.72),
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0x44E54C4C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x66E54C4C)),
      ),
      child: Text(
        message,
        style: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _WalletDialog extends StatefulWidget {
  const _WalletDialog({this.initial});

  final Wallet? initial;

  @override
  State<_WalletDialog> createState() => _WalletDialogState();
}

class _WalletDialogState extends State<_WalletDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _colorController;
  late final TextEditingController _currencyController;
  late WalletType _selectedType;
  late String _selectedIconName;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    final initialBalance = widget.initial?.balance ?? 0;
    _balanceController = TextEditingController(
      text: initialBalance == 0 ? '' : initialBalance.toString(),
    );
    _colorController = TextEditingController(text: widget.initial?.color ?? '');
    _currencyController =
        TextEditingController(text: widget.initial?.currencyCode ?? 'USD');
    _selectedType = widget.initial?.type ?? WalletType.physical;
    final initialIcon = widget.initial?.iconName ?? 'account_balance_wallet';
    _selectedIconName =
        IconLibrary.walletIcons.containsKey(initialIcon) ? initialIcon : IconLibrary.walletIcons.keys.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _colorController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final balanceText = _balanceController.text.trim();
    final balance = balanceText.isEmpty ? 0.0 : double.parse(balanceText);
    final iconName = _selectedIconName;
    final color = _colorController.text.trim();
    final currency = _currencyController.text.trim().isEmpty
        ? 'USD'
        : _currencyController.text.trim().toUpperCase();

    final wallet = (widget.initial ?? const Wallet()).copyWith(
      name: name,
      balance: balance,
      iconName: iconName,
      color: color,
      type: _selectedType,
      currencyCode: currency,
    );

    Navigator.of(context).pop(wallet);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit wallet' : 'New wallet'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a wallet name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WalletType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final type in WalletType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(_walletTypeLabel(type)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currencyController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Currency code'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a currency code';
                  }
                  if (value.trim().length != 3) {
                    return 'Currency codes are 3 letters (e.g. USD)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Balance (optional)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _IconChooser(
                label: 'Icon',
                options: IconLibrary.walletOptions(),
                selected: _selectedIconName,
                onSelected: (value) => setState(() => _selectedIconName = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color hex (optional)',
                  hintText: '#7B5BFF',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save changes' : 'Create'),
        ),
      ],
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.initial, required this.categories});

  final Category? initial;
  final List<Category> categories;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _colorController;
  late String _selectedIconName;
  String? _parentCategoryId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _colorController = TextEditingController(text: widget.initial?.color ?? '');
    _parentCategoryId = widget.initial?.parentCategoryId;
    final initialIcon = widget.initial?.iconName ?? 'shopping_bag';
    _selectedIconName = IconLibrary.categoryIcons.containsKey(initialIcon)
        ? initialIcon
        : IconLibrary.categoryIcons.keys.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final iconName = _selectedIconName;
    final color = _colorController.text.trim();

    final category = (widget.initial ?? const Category()).copyWith(
      name: name,
      iconName: iconName,
      color: color,
      parentCategoryId: _parentCategoryId,
    );

    Navigator.of(context).pop(category);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    final parentOptions = widget.categories
        .where((category) => category.id != widget.initial?.id)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return AlertDialog(
      title: Text(isEditing ? 'Edit category' : 'New category'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _IconChooser(
                label: 'Icon',
                options: IconLibrary.categoryOptions(),
                selected: _selectedIconName,
                onSelected: (value) => setState(() => _selectedIconName = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color hex (optional)',
                  hintText: '#FF6D8D',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _parentCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Parent category (optional)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  for (final category in parentOptions)
                    DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(
                        category.name.isNotEmpty
                            ? category.name
                            : 'Untitled category',
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _parentCategoryId = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save changes' : 'Create'),
        ),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.68),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF7B5BFF),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 18), footer!],
        ],
      ),
    );
  }
}

class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.white, 0.25)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.2),
            width: selected ? 3 : 1.6,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 24)
            : null,
      ),
    );
  }
}
