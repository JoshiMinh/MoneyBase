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
          _WalletSection(userId: userId, repository: walletRepository),
          const SizedBox(height: 32),
          _CategorySection(userId: userId, repository: categoryRepository),
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
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Create or edit wallets from the Add tab while recording transactions.',
          style: textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.72),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Wallet>>(
          stream: repository.watchWallets(userId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorNotice(
                message: 'Unable to load wallets: ${snapshot.error}',
              );
            }

            final wallets = snapshot.data ?? const <Wallet>[];
            final loading =
                snapshot.connectionState == ConnectionState.waiting &&
                wallets.isEmpty;

            if (loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (wallets.isEmpty) {
              return const _EmptyNotice(
                message:
                    'No wallets yet. Use the Add tab to create one and track balances.',
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wallets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                final title = wallet.name.isNotEmpty
                    ? wallet.name
                    : 'Untitled wallet';
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
                    backgroundColor:
                        accent?.withOpacity(0.2) ??
                        Colors.white.withOpacity(0.08),
                    child: Icon(iconData, color: accent ?? Colors.white),
                  ),
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
            snapshot.connectionState == ConnectionState.waiting &&
            categories.isEmpty;

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
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your category library from the Add tab to keep selections in sync.',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.72),
              ),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (categories.isEmpty)
              const _EmptyNotice(
                message:
                    'No categories yet. Use the Add tab to create one to organise transactions.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final title = category.name.isNotEmpty
                      ? category.name
                      : 'Untitled category';
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

                  final iconData = IconLibrary.iconForCategory(
                    category.iconName,
                  );
                  final accent = parseHexColor(category.color);

                  return _SettingsListTile(
                    title: title,
                    metadata: metadata,
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          accent?.withOpacity(0.2) ??
                          Colors.white.withOpacity(0.08),
                      child: Icon(iconData, color: accent ?? Colors.white),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  const _SettingsListTile({
    required this.title,
    required this.metadata,
    this.onEdit,
    this.onDelete,
    this.leading,
  });

  final String title;
  final List<String> metadata;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
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
          if (leading != null) ...[leading!, const SizedBox(width: 16)],
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
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.white,
                  ),
                if (onEdit != null && onDelete != null)
                  const SizedBox(width: 4),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.white,
                  ),
              ],
            ),
          ],
        ],
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
