part of 'package:moneybase/features/app_shell/presentation/app_shell.dart';

class _ShellNavigationDrawer extends StatelessWidget {
  const _ShellNavigationDrawer({
    required this.destinations,
    required this.secondaryDestinations,
    required this.selected,
    required this.onSelect,
  });

  final List<_NavigationDestination> destinations;
  final List<_NavigationDestination> secondaryDestinations;
  final _NavigationDestination? selected;
  final ValueChanged<_NavigationDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = context.themeColors;
    final backgroundColor = themeColors.surfaceBackground;
    final dividerColor = themeColors.surfaceBorder;
    final titleColor = themeColors.primaryText;

    return Drawer(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icon.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'MoneyBase',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final destination in destinations)
                    _DrawerDestinationTile(
                      destination: destination,
                      selected: destination == selected,
                      onTap: () => onSelect(destination),
                    ),
                ],
              ),
            ),
            if (destinations.isNotEmpty && secondaryDestinations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  color: dividerColor,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _DrawerPremiumButton(),
                  if (secondaryDestinations.isNotEmpty)
                    const SizedBox(height: 12),
                  for (final destination in secondaryDestinations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DrawerDestinationTile(
                        destination: destination,
                        selected: destination == selected,
                        onTap: () => onSelect(destination),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerDestinationTile extends StatelessWidget {
  const _DrawerDestinationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColors = context.themeColors;
    final activeColor = themeColors.primaryAccent;
    final inactiveColor = themeColors.mutedText;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      hoverColor: themeColors.secondaryAccent.withOpacity(isDark ? 0.2 : 0.12),
      splashColor: activeColor.withOpacity(0.18),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? activeColor.withOpacity(isDark ? 0.28 : 0.12)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            _DestinationIcon(
              destination: destination,
              iconColor: selected ? activeColor : inactiveColor,
              isSelected: selected,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                destination.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? activeColor : inactiveColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerPremiumButton extends StatelessWidget {
  const _DrawerPremiumButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColors = context.themeColors;
    final accent = themeColors.primaryAccent;

    return FilledButton.icon(
      onPressed: () => _openPremiumScreen(context),
      icon: const Icon(Icons.workspace_premium_outlined),
      label: const Text('Go Premium'),
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Colors.white.withOpacity(isDark ? 0.16 : 0.08),
          ),
        ),
      ),
    );
  }
}
