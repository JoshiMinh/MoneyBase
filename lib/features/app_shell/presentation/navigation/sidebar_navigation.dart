import 'package:flutter/material.dart';

import '../../../../app/theme/theme.dart';
import 'app_shell_destination.dart';

const _kSidebarWidth = 92.0;
const _kSidebarAnimationDuration = Duration(milliseconds: 220);

class SidebarNavigation extends StatelessWidget {
  const SidebarNavigation({
    required this.destinations,
    required this.secondaryDestinations,
    required this.selected,
    required this.onSelect,
    this.onOpenAssistant,
    super.key,
  });

  final List<AppShellDestination> destinations;
  final List<AppShellDestination> secondaryDestinations;
  final AppShellDestination? selected;
  final ValueChanged<AppShellDestination> onSelect;
  final VoidCallback? onOpenAssistant;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;

    final surfaceColor = Color.alphaBlend(
      colors.glassOverlay,
      colors.surfaceElevated,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: colors.surfaceBorder),
                boxShadow: [
                  BoxShadow(
                    color: colors.surfaceShadow,
                    blurRadius: 28,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              child: SizedBox(
                width: _kSidebarWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SidebarHeading(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SidebarSection(
                              destinations: destinations,
                              selected: selected,
                              onSelect: onSelect,
                            ),
                            const SizedBox(height: 22),
                            const _PremiumPlaceholderButton(),
                            if (secondaryDestinations.isNotEmpty) ...[
                              const SizedBox(height: 26),
                              _SidebarSection(
                                destinations: secondaryDestinations,
                                selected: selected,
                                onSelect: onSelect,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onOpenAssistant != null)
              Positioned(
                right: -20,
                bottom: 110,
                child: _SidebarChatButton(
                  onPressed: onOpenAssistant!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeading extends StatelessWidget {
  const _SidebarHeading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MoneyBase',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: colors.primaryText,
                  letterSpacing: 0.2,
                ) ??
                TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: colors.primaryText,
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primaryAccent.withOpacity(0.9),
                  colors.secondaryAccent.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const SizedBox(height: 3, width: 32),
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.destinations,
    required this.selected,
    required this.onSelect,
  });

  final List<AppShellDestination> destinations;
  final AppShellDestination? selected;
  final ValueChanged<AppShellDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (final destination in destinations)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _SidebarItem(
              destination: destination,
              selected: destination == selected,
              onTap: () => onSelect(destination),
            ),
          ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
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
    final colors = context.moneyBaseColors;
    final backgroundColor = selected
        ? Color.alphaBlend(colors.glassOverlay, colors.surfaceElevated)
        : Colors.transparent;
    final borderColor = selected
        ? colors.primaryAccent.withOpacity(0.75)
        : colors.surfaceBorder.withOpacity(0.8);
    final iconColor = selected ? colors.primaryAccent : colors.mutedText;
    final textColor = selected ? colors.primaryText : colors.mutedText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: _kSidebarAnimationDuration,
          curve: Curves.easeOutCubic,
          height: 74,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.primaryAccent.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SidebarItemIcon(
                  destination: destination,
                  selected: selected,
                  color: iconColor,
                ),
                const SizedBox(height: 8),
                AnimatedDefaultTextStyle(
                  duration: _kSidebarAnimationDuration,
                  curve: Curves.easeOutCubic,
                  style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ) ??
                      TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                  textAlign: TextAlign.center,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _PremiumPlaceholderButton extends StatelessWidget {
  const _PremiumPlaceholderButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryAccent,
            colors.secondaryAccent,
            colors.tertiaryAccent,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.primaryAccent.withOpacity(0.32),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.workspace_premium_outlined, color: Colors.white),
            SizedBox(height: 12),
            Text(
              'Upgrade to Premium',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItemIcon extends StatelessWidget {
  const _SidebarItemIcon({
    required this.destination,
    required this.selected,
    required this.color,
  });

  final AppShellDestination destination;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (destination == AppShellDestination.home) {
      final colors = context.moneyBaseColors;

      return AnimatedContainer(
        duration: _kSidebarAnimationDuration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    colors.primaryAccent.withOpacity(0.95),
                    colors.secondaryAccent.withOpacity(0.9),
                  ],
                )
              : null,
          color: selected
              ? null
              : Color.alphaBlend(colors.glassOverlay, colors.surfaceElevated),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? colors.primaryAccent.withOpacity(0.9)
                : colors.surfaceBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primaryAccent.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'web/favicon.png',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: _kSidebarAnimationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Icon(
        selected ? destination.selectedIcon : destination.icon,
        key: ValueKey<bool>(selected),
        color: color,
      ),
    );
  }
}

class _SidebarChatButton extends StatelessWidget {
  const _SidebarChatButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.secondaryAccent,
                colors.primaryAccent,
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: colors.secondaryAccent.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.smart_toy_outlined, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
