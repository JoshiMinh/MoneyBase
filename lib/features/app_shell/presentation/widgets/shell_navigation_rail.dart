part of 'package:moneybase/features/app_shell/presentation/app_shell.dart';

class _ResponsiveNavigationRail extends StatelessWidget {
  const _ResponsiveNavigationRail({
    required this.destinations,
    required this.secondaryDestinations,
    required this.selected,
    required this.extended,
    required this.onSelect,
  });

  static const _animationDuration = Duration(milliseconds: 250);

  final List<_NavigationDestination> destinations;
  final List<_NavigationDestination> secondaryDestinations;
  final _NavigationDestination? selected;
  final bool extended;
  final ValueChanged<_NavigationDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final background = themeColors.surfaceBackground;
    final borderColor = themeColors.surfaceBorder;

    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeInOut,
      width: extended ? 260 : 88,
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        left: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment:
                extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: extended ? 20 : 0),
                  child: _RailHeader(extended: extended),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 0),
                  child: _RailDestinationList(
                    destinations: destinations,
                    extended: extended,
                    selected: selected,
                    onSelect: onSelect,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 0),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: extended
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    _RailPremiumButton(extended: extended),
                    const SizedBox(height: 12),
                    for (final destination in secondaryDestinations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RailDestinationTile(
                          destination: destination,
                          extended: extended,
                          isSelected: destination == selected,
                          onTap: () => onSelect(destination),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader({
    required this.extended,
  });

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = context.themeColors;
    final textColor = themeColors.primaryText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/icon.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.horizontal,
                  axisAlignment: -1,
                  child: child,
                ),
              ),
              child: extended
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'MoneyBase',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        if (extended) const SizedBox(height: 24),
      ],
    );
  }
}

class _RailDestinationList extends StatelessWidget {
  const _RailDestinationList({
    required this.destinations,
    required this.extended,
    required this.selected,
    required this.onSelect,
  });

  final List<_NavigationDestination> destinations;
  final bool extended;
  final _NavigationDestination? selected;
  final ValueChanged<_NavigationDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment:
            extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          for (final destination in destinations)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RailDestinationTile(
                destination: destination,
                extended: extended,
                isSelected: destination == selected,
                onTap: () => onSelect(destination),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailDestinationTile extends StatelessWidget {
  const _RailDestinationTile({
    required this.destination,
    required this.extended,
    required this.isSelected,
    required this.onTap,
  });

  static const _indicatorWidth = 3.0;
  static const _animationDuration = Duration(milliseconds: 220);

  final _NavigationDestination destination;
  final bool extended;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColors = context.themeColors;
    final accent = themeColors.primaryAccent;
    final inactiveTextColor = themeColors.mutedText;
    final iconColor = isSelected ? accent : inactiveTextColor;
    final textStyle = theme.textTheme.titleMedium?.copyWith(
      color: isSelected ? accent : inactiveTextColor,
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
    );
    final tooltipMessage = destination.label;
    final iconWidget = _DestinationIcon(
      destination: destination,
      iconColor: iconColor,
      isSelected: isSelected,
    );

    if (extended) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          hoverColor: themeColors.secondaryAccent.withOpacity(isDark ? 0.18 : 0.1),
          splashColor: accent.withOpacity(0.18),
          highlightColor: accent.withOpacity(isDark ? 0.24 : 0.14),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withOpacity(isDark ? 0.24 : 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: _animationDuration,
                  curve: Curves.easeInOut,
                  height: 36,
                  width: _indicatorWidth,
                  decoration: BoxDecoration(
                    color: isSelected ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(_indicatorWidth),
                  ),
                ),
                const SizedBox(width: 12),
                iconWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    textAlign: TextAlign.left,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final collapsedTile = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: themeColors.secondaryAccent.withOpacity(isDark ? 0.18 : 0.1),
        splashColor: accent.withOpacity(0.18),
        highlightColor: accent.withOpacity(isDark ? 0.24 : 0.14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withOpacity(isDark ? 0.24 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: _animationDuration,
                curve: Curves.easeInOut,
                height: 4,
                width: 16,
                decoration: BoxDecoration(
                  color: isSelected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Tooltip(
      message: tooltipMessage,
      waitDuration: const Duration(milliseconds: 400),
      preferBelow: false,
      child: collapsedTile,
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  const _DestinationIcon({
    required this.destination,
    required this.iconColor,
    required this.isSelected,
  });

  final _NavigationDestination destination;
  final Color iconColor;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      isSelected ? destination.selectedIcon : destination.icon,
      color: iconColor,
      size: 24,
    );
    final badgeCount = destination.badgeCount ?? 0;
    if (badgeCount <= 0) {
      return icon;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -4,
          child: _NotificationBadge(count: badgeCount),
        ),
      ],
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayCount = count > 9 ? '9+' : '$count';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.onError, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
        child: Text(
          displayCount,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onError,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RailPremiumButton extends StatelessWidget {
  const _RailPremiumButton({required this.extended});

  static const _animationDuration = Duration(milliseconds: 220);

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColors = context.themeColors;
    final accent = themeColors.primaryAccent;

    return Tooltip(
      message: 'Premium',
      waitDuration: const Duration(milliseconds: 400),
      triggerMode:
          extended ? TooltipTriggerMode.manual : TooltipTriggerMode.longPress,
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: Curves.easeInOut,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: accent,
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(isDark ? 0.4 : 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withOpacity(0.12),
            highlightColor: Colors.white.withOpacity(0.08),
            onTap: () => _openPremiumScreen(context),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: extended ? 16 : 0,
                vertical: 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    color: Colors.white,
                  ),
                  if (extended) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Go Premium',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
