import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Layout metadata describing how wide layouts should render within the shell.
class MoneyBaseLayout {
  const MoneyBaseLayout({
    required this.isWide,
    required this.contentPadding,
    required this.maxContentWidth,
  });

  final bool isWide;
  final EdgeInsets contentPadding;
  final double maxContentWidth;
}

typedef MoneyBaseScaffoldBuilder = Widget Function(
  BuildContext context,
  MoneyBaseLayout layout,
);

/// Gradient scaffold used across Android and web surfaces to keep spacing uniform.
class MoneyBaseScaffold extends StatelessWidget {
  const MoneyBaseScaffold({
    required this.builder,
    this.maxContentWidth = 1080,
    this.breakpoint = 900,
    this.narrowPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    this.widePadding = const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
    this.scrollController,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    super.key,
  });

  final MoneyBaseScaffoldBuilder builder;
  final double maxContentWidth;
  final double breakpoint;
  final EdgeInsets narrowPadding;
  final EdgeInsets widePadding;
  final ScrollController? scrollController;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: _buildShellDecoration(context),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= breakpoint;
              final padding = isWide ? widePadding : narrowPadding;
              final layout = MoneyBaseLayout(
                isWide: isWide,
                contentPadding: padding,
                maxContentWidth: maxContentWidth,
              );

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: padding,
                    child: builder(context, layout),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

BoxDecoration _buildShellDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final extension = theme.extension<MoneyBaseThemeColors>();
  final gradientColors = extension?.backgroundGradient;

  if (gradientColors != null && gradientColors.length >= 2) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ),
    );
  }

  return BoxDecoration(color: theme.colorScheme.background);
}

/// Glassmorphism-inspired card used for analytic content across MoneyBase views.
class MoneyBaseSurface extends StatelessWidget {
  const MoneyBaseSurface({
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.borderRadius = 32,
    this.backgroundColor,
    this.borderColor,
    this.shadow,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final theme = Theme.of(context);
    final shouldBlendOverlay =
        backgroundColor == null && theme.brightness == Brightness.dark;
    final surfaceColor = backgroundColor ??
        (shouldBlendOverlay
            ? Color.alphaBlend(colors.glassOverlay, colors.surfaceBackground)
            : colors.surfaceBackground);
    final border = borderColor ?? colors.surfaceBorder;
    final resolvedShadow = shadow ??
        BoxShadow(
          color: colors.surfaceShadow,
          blurRadius: 28,
          offset: const Offset(0, 18),
          spreadRadius: shouldBlendOverlay ? 0 : -4,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border),
        boxShadow: [resolvedShadow],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Frosted glass panel with backdrop blur for forms and settings surfaces.
class MoneyBaseFrostedPanel extends StatelessWidget {
  const MoneyBaseFrostedPanel({
    required this.child,
    this.padding,
    this.borderRadius = 32,
    this.blurSigma = 28,
    this.backgroundOpacity = 0.08,
    this.borderOpacity = 0.12,
    this.boxShadow,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurSigma;
  final double backgroundOpacity;
  final double borderOpacity;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final overlayColor = theme.brightness == Brightness.dark
        ? colors.glassOverlay
        : Colors.white.withOpacity(backgroundOpacity);
    final borderColor = theme.brightness == Brightness.dark
        ? colors.surfaceBorder.withOpacity(0.8)
        : Colors.black.withOpacity(borderOpacity);
    final resolvedShadows = boxShadow ??
        [
          BoxShadow(
            color: colors.surfaceShadow.withOpacity(0.35),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: overlayColor,
            border: Border.all(color: borderColor),
            boxShadow: resolvedShadows,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Rounded icon button with translucent fill used for header controls.
class MoneyBaseGlassIconButton extends StatelessWidget {
  const MoneyBaseGlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 18,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);
    final iconColor = theme.brightness == Brightness.dark
        ? Colors.white
        : colorScheme.onSurface;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }
}
