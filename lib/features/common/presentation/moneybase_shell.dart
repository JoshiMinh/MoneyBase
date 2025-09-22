import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Shared gradient constants for the refreshed MoneyBase shell.
class MoneyBaseGradients {
  const MoneyBaseGradients._();

  static const frosted = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x66382A66),
      Color(0x3329214A),
    ],
  );
}

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
    super.key,
  });

  final MoneyBaseScaffoldBuilder builder;
  final double maxContentWidth;
  final double breakpoint;
  final EdgeInsets narrowPadding;
  final EdgeInsets widePadding;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: MoneyBaseGradients.frosted,
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.white.withOpacity(backgroundOpacity),
            border: Border.all(color: Colors.white.withOpacity(borderOpacity)),
            boxShadow: boxShadow,
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
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
