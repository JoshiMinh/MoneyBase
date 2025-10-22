import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/shape_tokens.dart';
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
class MoneyBaseScaffold extends StatefulWidget {
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
  State<MoneyBaseScaffold> createState() => _MoneyBaseScaffoldState();
}

class _MoneyBaseScaffoldState extends State<MoneyBaseScaffold> {
  final GlobalKey _contentKey = GlobalKey();
  bool _shouldScroll = true;
  double? _lastMaxHeight;
  bool _measurementScheduled = false;

  void _scheduleMeasurement(double maxHeight) {
    _lastMaxHeight = maxHeight;
    if (_measurementScheduled) {
      return;
    }
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      final context = _contentKey.currentContext;
      if (context == null || !context.mounted) {
        return;
      }
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        return;
      }
      final height = renderObject.size.height;
      final availableHeight = _lastMaxHeight;
      if (availableHeight == null) {
        return;
      }
      final needsScroll = height > availableHeight;
      if (needsScroll != _shouldScroll && mounted) {
        setState(() {
          _shouldScroll = needsScroll;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      body: Container(
        decoration: _buildShellDecoration(context),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= widget.breakpoint;
              final padding = isWide ? widget.widePadding : widget.narrowPadding;
              final layout = MoneyBaseLayout(
                isWide: isWide,
                contentPadding: padding,
                maxContentWidth: widget.maxContentWidth,
              );

              _scheduleMeasurement(constraints.maxHeight);

              final paddedContent = Padding(
                key: _contentKey,
                padding: padding,
                child: widget.builder(context, layout),
              );

              final child = _shouldScroll
                  ? SingleChildScrollView(
                      controller: widget.scrollController,
                      padding: EdgeInsets.zero,
                      child: paddedContent,
                    )
                  : paddedContent;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
                  child: SelectionArea(
                    child: child,
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
    this.borderRadius = MoneyBaseShapeTokens.cornerLarge,
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
    final surfaceColor = backgroundColor ?? colors.surfaceBackground;
    final border = borderColor ?? colors.surfaceBorder;
    final resolvedShadow = shadow ??
        BoxShadow(
          color: colors.surfaceShadow,
          blurRadius: 24,
          offset: const Offset(0, 16),
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
    this.borderRadius = MoneyBaseShapeTokens.cornerLarge,
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
    final overlayBase =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: overlayBase.withOpacity(backgroundOpacity),
            border: Border.all(color: overlayBase.withOpacity(borderOpacity)),
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
    this.borderRadius = MoneyBaseShapeTokens.cornerMedium,
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
