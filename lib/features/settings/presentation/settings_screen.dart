import 'dart:ui';

import 'package:flutter/material.dart';

import '../../common/presentation/moneybase_shell.dart';
import '../../../app/theme/palettes.dart';
import '../../../app/theme/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 17, minute: 25);

  Future<void> _pickReminderTime(BuildContext context) async {
    final result = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (result != null) {
      setState(() => _reminderTime = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ThemeControllerProvider.of(context);
    final textTheme = Theme.of(context).textTheme;
    final reminderLabel = _reminderTime.format(context);

    return MoneyBaseScaffold(
      maxContentWidth: 960,
      widePadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
      builder: (context, layout) {
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
                  _ProfileHeader(textTheme: textTheme),
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
                            disabledForegroundColor:
                                Colors.white.withOpacity(0.4),
                            backgroundColor: _remindersEnabled
                                ? Colors.white.withOpacity(0.12)
                                : Colors.white.withOpacity(0.06),
                            disabledBackgroundColor:
                                Colors.white.withOpacity(0.04),
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
                    subtitle: 'Match Android\'s amethyst dark finish instantly.',
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
                          selected:
                              controller.palette == kMoneyBasePalettes[i],
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
                          onPressed: widget.onLogout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Log out'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF5D9BFF), Color(0xFF7B5BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 2),
          ),
          child: const Icon(
            Icons.public,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Joshi Minh',
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'binhangia241273@gmail.com',
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
          if (footer != null) ...[
            const SizedBox(height: 18),
            footer!,
          ],
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
            colors: [
              color,
              Color.lerp(color, Colors.white, 0.25)!,
            ],
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
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }
}
