import 'package:flutter/material.dart';

import '../app_shell_destinations.dart';

const double kSidebarRailWidth = 120.0;

class SidebarNavigation extends StatelessWidget {
  const SidebarNavigation({
    required this.destinations,
    required this.secondaryDestinations,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<AppShellDestination> destinations;
  final List<AppShellDestination> secondaryDestinations;
  final AppShellDestination? selected;
  final ValueChanged<AppShellDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final railBackground = isDark
        ? colorScheme.surfaceVariant.withOpacity(0.42)
        : colorScheme.surface.withOpacity(0.92);
    final borderColor = colorScheme.outlineVariant.withOpacity(0.35);
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.6)
        : Colors.black.withOpacity(0.08);

    final homeDestination =
        destinations.isNotEmpty ? destinations.first : null;
    final primaryDestinations = homeDestination != null
        ? destinations.sublist(1)
        : destinations;

    return SafeArea(
      child: SizedBox(
        width: kSidebarRailWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: railBackground,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 26,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                if (homeDestination != null)
                  _SidebarBrandButton(
                    destination: homeDestination,
                    selected: homeDestination == selected,
                    onTap: () => onSelect(homeDestination),
                  ),
                if (homeDestination != null &&
                    primaryDestinations.isNotEmpty)
                  const Divider(
                    height: 20,
                    thickness: 1,
                    indent: 18,
                    endIndent: 18,
                  )
                else
                  const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        for (var i = 0;
                            i < primaryDestinations.length;
                            i++) ...[
                          _SidebarItem(
                            destination: primaryDestinations[i],
                            selected: primaryDestinations[i] == selected,
                            onTap: () => onSelect(primaryDestinations[i]),
                          ),
                          if (i != primaryDestinations.length - 1)
                            const SizedBox(height: 12),
                        ],
                        const Spacer(),
                        const _PremiumPlaceholderButton(),
                        if (secondaryDestinations.isNotEmpty)
                          const SizedBox(height: 16),
                        for (var i = 0;
                            i < secondaryDestinations.length;
                            i++) ...[
                          _SidebarItem(
                            destination: secondaryDestinations[i],
                            selected: secondaryDestinations[i] == selected,
                            onTap: () => onSelect(secondaryDestinations[i]),
                            compact: true,
                          ),
                          if (i != secondaryDestinations.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarFloatingActionButton extends StatelessWidget {
  const SidebarFloatingActionButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
        borderRadius: BorderRadius.circular(28),
      ),
      child: FloatingActionButton.small(
        heroTag: 'aiChatRailFab',
        onPressed: onPressed,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.smart_toy_outlined),
      ),
    );
  }
}

class _SidebarBrandButton extends StatelessWidget {
  const _SidebarBrandButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final background = selected
        ? colorScheme.primary.withOpacity(isDark ? 0.28 : 0.16)
        : colorScheme.surfaceVariant.withOpacity(isDark ? 0.4 : 0.32);
    final borderColor = selected
        ? colorScheme.primary.withOpacity(0.45)
        : colorScheme.outlineVariant.withOpacity(0.28);
    final labelColor = selected
        ? colorScheme.primary
        : colorScheme.onSurface.withOpacity(0.85);
    final iconColor = selected ? colorScheme.onPrimary : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'app_icon.ico',
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            selected
                                ? destination.selectedIcon
                                : destination.icon,
                            size: 14,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  destination.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: labelColor,
                  ),
                ),
                Text(
                  'MoneyBase',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: labelColor.withOpacity(0.74),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final AppShellDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final background = selected
        ? colorScheme.primary.withOpacity(isDark ? 0.24 : 0.16)
        : colorScheme.surfaceVariant.withOpacity(isDark ? 0.22 : 0.18);
    final borderColor = selected
        ? colorScheme.primary.withOpacity(0.45)
        : colorScheme.outlineVariant.withOpacity(0.28);
    final labelColor = selected
        ? colorScheme.primary
        : colorScheme.onSurface.withOpacity(0.86);
    final iconColor = selected ? colorScheme.onPrimary : colorScheme.primary;
    final iconData = selected ? destination.selectedIcon : destination.icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                  border: Border.all(
                    color: colorScheme.surfaceVariant.withOpacity(0.32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: compact ? 20 : 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumPlaceholderButton extends StatelessWidget {
  const _PremiumPlaceholderButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentGradient = LinearGradient(
      colors: [
        colorScheme.primary.withOpacity(0.2),
        colorScheme.secondaryContainer.withOpacity(0.16),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Tooltip(
        message: 'Premium (coming soon)',
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: accentGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary.withOpacity(0.32)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {},
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock premium',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI automation coming soon',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
