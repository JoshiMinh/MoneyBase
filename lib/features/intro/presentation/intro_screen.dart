import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../common/presentation/moneybase_shell.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lightTheme = MoneyBaseTheme.buildTheme(darkMode: false);

    return Theme(
      data: lightTheme,
      child: MoneyBaseScaffold(
        maxContentWidth: 1120,
        widePadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 72),
        narrowPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        builder: (context, layout) {
          final size = MediaQuery.sizeOf(context);
          final verticalPadding = layout.contentPadding.vertical;
          final minHeight =
              (size.height - verticalPadding).clamp(0.0, double.infinity);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: layout.isWide ? 1080 : 560,
                minHeight: minHeight,
              ),
              child: _IntroBody(isWide: layout.isWide),
            ),
          );
        },
      ),
    );
  }
}

class _IntroBody extends StatelessWidget {
  const _IntroBody({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final baseTextColor = Colors.white;
    final resolvedTopSpacing = _resolveTopSpacing(screenHeight);

    final lead = _IntroLead(isWide: isWide, textColor: baseTextColor);
    final preview = const _IntroPreview();

    final mainContent = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: lead),
              const SizedBox(width: 48),
              Expanded(child: preview),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              lead,
              const SizedBox(height: 32),
              preview,
            ],
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: resolvedTopSpacing),
          mainContent,
          const SizedBox(height: 48),
          Text(
            'MoneyBase © 2025',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  double _resolveTopSpacing(double screenHeight) {
    final topSpacing = (screenHeight * 0.26) - 140;
    if (!topSpacing.isFinite) {
      return 24;
    }
    return topSpacing.clamp(24.0, screenHeight * 0.22);
  }
}

class _IntroLead extends StatelessWidget {
  const _IntroLead({required this.isWide, required this.textColor});

  final bool isWide;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final bodyColor = Colors.white.withOpacity(0.82);
    final subtextColor = Colors.white.withOpacity(0.74);
    final alignment = isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = isWide ? TextAlign.start : TextAlign.center;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        _LogoLockup(isWide: isWide, textColor: textColor),
        const SizedBox(height: 32),
        Text(
          'Designed for mindful money management',
          textAlign: textAlign,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'MoneyBase brings budgets, analytics, and shared lists together so you can focus on what matters most.',
          textAlign: textAlign,
          style: theme.textTheme.titleMedium?.copyWith(
            color: bodyColor,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        _IntroButtons(isWide: isWide, accentColor: colors.primaryAccent),
        const SizedBox(height: 32),
        Wrap(
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 18,
          runSpacing: 16,
          children: const [
            _IntroHighlight(
              icon: Icons.auto_graph_rounded,
              label: 'Live spending analytics',
            ),
            _IntroHighlight(
              icon: Icons.hub_outlined,
              label: 'Shared spaces that stay in sync',
            ),
            _IntroHighlight(
              icon: Icons.shield_outlined,
              label: 'Secure by Firebase Auth',
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Trusted by teams keeping track of every expense, subscription, and shared goal.',
          textAlign: textAlign,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: subtextColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _LogoLockup extends StatelessWidget {
  const _LogoLockup({required this.isWide, required this.textColor});

  final bool isWide;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isWide ? Alignment.centerLeft : Alignment.center;
    final crossAxis = isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: crossAxis,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/icon.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'MoneyBase',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroButtons extends StatelessWidget {
  const _IntroButtons({required this.isWide, required this.accentColor});

  final bool isWide;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isWide ? WrapAlignment.start : WrapAlignment.center;

    return Wrap(
      alignment: alignment,
      spacing: 16,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pushNamed('/auth'),
          icon: const Icon(Icons.lock_open_rounded),
          label: const Text('Sign in or create account'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            foregroundColor: Colors.white,
            backgroundColor: accentColor,
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pushNamed('/'),
          icon: const Icon(Icons.dashboard_customize_rounded),
          label: const Text('Browse the dashboard'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.65)),
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => _showInstallPlaceholder(context),
          icon: const Icon(Icons.android_rounded),
          label: const Text('Install on Google Play'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showInstallPlaceholder(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Google Play install is coming soon.'),
      ),
    );
  }
}

class _IntroHighlight extends StatelessWidget {
  const _IntroHighlight({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = Colors.white;

    return MoneyBaseFrostedPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: 22,
      backgroundOpacity: 0.16,
      borderOpacity: 0.2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPreview extends StatelessWidget {
  const _IntroPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final headingColor = Colors.white;
    final bodyColor = Colors.white.withOpacity(0.8);
    final captionColor = Colors.white.withOpacity(0.72);
    final accent = colors.primaryAccent;
    final secondaryAccent = colors.secondaryAccent;

    return MoneyBaseFrostedPanel(
      padding: const EdgeInsets.all(32),
      borderRadius: 34,
      backgroundOpacity: 0.14,
      borderOpacity: 0.18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bring clarity to every decision',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: headingColor,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 168,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  accent.withOpacity(0.32),
                  secondaryAccent.withOpacity(0.24),
                ],
              ),
            ),
            child: const _PreviewSparkline(),
          ),
          const SizedBox(height: 18),
          Text(
            'Visualize budgets, collaborate on lists, and get nudges when you drift off track.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: bodyColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(
                child: _PreviewStat(
                  label: 'Budgets on track',
                  value: '92%',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _PreviewStat(
                  label: 'Shared lists',
                  value: '18',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Updated just now',
              style: theme.textTheme.labelSmall?.copyWith(
                color: captionColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.75),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _PreviewSparkline extends StatelessWidget {
  const _PreviewSparkline();

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final color = colors.secondaryAccent;

    return CustomPaint(
      painter: _SparklinePainter(color),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final controlPoints = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.18, size.height * 0.25),
      Offset(size.width * 0.35, size.height * 0.5),
      Offset(size.width * 0.55, size.height * 0.2),
      Offset(size.width * 0.72, size.height * 0.65),
      Offset(size.width * 0.9, size.height * 0.35),
      Offset(size.width, size.height * 0.45),
    ];

    path.moveTo(controlPoints.first.dx, controlPoints.first.dy);
    for (var i = 1; i < controlPoints.length; i++) {
      final previous = controlPoints[i - 1];
      final current = controlPoints[i];
      final midpoint = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(previous.dx, previous.dy, midpoint.dx, midpoint.dy);
    }
    final last = controlPoints.last;
    path.lineTo(last.dx, last.dy);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final point in controlPoints.skip(1)) {
      canvas.drawCircle(point, 6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
