import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme.dart';
import '../../common/presentation/moneybase_shell.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lightTheme = MoneyBaseTheme.buildTheme(darkMode: false);
    final themeColors = lightTheme.extension<MoneyBaseThemeColors>();
    final primaryAccent = themeColors?.primaryAccent ?? lightTheme.colorScheme.primary;
    final secondaryAccent =
        themeColors?.secondaryAccent ?? lightTheme.colorScheme.secondary;
    final tertiaryAccent =
        themeColors?.tertiaryAccent ?? MoneyBaseColors.tertiary;

    final gradientColors = <Color>[
      primaryAccent,
      Color.lerp(primaryAccent, secondaryAccent, 0.35) ?? secondaryAccent,
      secondaryAccent,
      Color.lerp(secondaryAccent, tertiaryAccent, 0.5) ?? tertiaryAccent,
    ];

    return Theme(
      data: lightTheme,
      child: Scaffold(
        backgroundColor: lightTheme.colorScheme.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                left: -70,
                child: _BlurredOrb(
                  size: 320,
                  color: secondaryAccent.withOpacity(0.4),
                ),
              ),
              Positioned(
                bottom: -160,
                right: -60,
                child: _BlurredOrb(
                  size: 360,
                  color: tertiaryAccent.withOpacity(0.32),
                ),
              ),
              Positioned(
                top: 220,
                right: -100,
                child: _BlurredOrb(
                  size: 220,
                  color: primaryAccent.withOpacity(0.28),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 48,
                      ),
                      child: const _IntroContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    const headingColor = Colors.white;
    final bodyColor = Colors.white.withOpacity(0.88);
    final badgesColor = Colors.white.withOpacity(0.94);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 860;
        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MoneyBaseFrostedPanel(
              backgroundOpacity: 0.18,
              borderOpacity: 0.22,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              borderRadius: 26,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/icon.png',
                      height: 64,
                      width: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MoneyBase',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: headingColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        'Personal finance without the noise',
                        style: textTheme.labelLarge?.copyWith(
                          color: bodyColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'A calmer way to see your finances.',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.12,
                color: headingColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Launch the dashboard or jump straight into sign-in. MoneyBase keeps budgets, shared shopping lists, and analytics aligned with your goals.',
              style: textTheme.titleMedium?.copyWith(
                color: bodyColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 20,
              runSpacing: 16,
              children: [
                FilledButton.icon(
                  onPressed: () => _open(context, '/'),
                  icon: const Icon(Icons.dashboard_customize_rounded),
                  label: const Text('Enter MoneyBase'),
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        theme.extension<MoneyBaseThemeColors>()?.primaryAccent ??
                            theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 20,
                    ),
                    textStyle: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _open(context, '/auth'),
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('Sign in or create account'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    side: BorderSide(color: Colors.white.withOpacity(0.65)),
                    foregroundColor: Colors.white,
                    textStyle: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showInstallPlaceholder(context),
                  icon: const Icon(Icons.android_rounded),
                  label: const Text('Install on Google Play'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    foregroundColor: badgesColor,
                    textStyle: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Wrap(
              spacing: 18,
              runSpacing: 18,
              children: const [
                _IntroBadge(icon: Icons.insights_outlined, label: 'Live analytics dashboards'),
                _IntroBadge(icon: Icons.hub_outlined, label: 'Unified wallets & lists'),
                _IntroBadge(icon: Icons.verified_user_outlined, label: 'Backed by Firebase Auth'),
              ],
            ),
          ],
        );

        if (!isWide) {
          return column;
        }

        return Row(
          children: [
            Expanded(child: column),
            const SizedBox(width: 48),
            const Expanded(
              child: _IntroPreviewPanel(),
            ),
          ],
        );
      },
    );
  }

  void _open(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
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

class _IntroBadge extends StatelessWidget {
  const _IntroBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = Colors.white;

    return MoneyBaseFrostedPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      borderRadius: 20,
      backgroundOpacity: 0.22,
      borderOpacity: 0.24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPreviewPanel extends StatelessWidget {
  const _IntroPreviewPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<MoneyBaseThemeColors>();
    final surface = colors?.surfaceBackground.withOpacity(0.18) ??
        Colors.white.withOpacity(0.14);
    final headingColor = Colors.white;
    final bodyColor = Colors.white.withOpacity(0.78);
    final accent = colors?.primaryAccent ?? theme.colorScheme.primary;

    return Align(
      alignment: Alignment.centerRight,
      child: Transform.rotate(
        angle: -4 * math.pi / 180,
        child: MoneyBaseFrostedPanel(
          borderRadius: 36,
          padding: const EdgeInsets.all(28),
          backgroundOpacity: 0.2,
          borderOpacity: 0.24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Plan with clarity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: headingColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      surface,
                      Color.lerp(surface, accent.withOpacity(0.22), 0.5) ?? surface,
                    ],
                  ),
                ),
                child: const _PreviewSparkline(),
              ),
              const SizedBox(height: 16),
              Text(
                'Keep tabs on spending trends, budgets, and shared lists in one workspace.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewSparkline extends StatelessWidget {
  const _PreviewSparkline();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<MoneyBaseThemeColors>();
    final color = colors?.secondaryAccent ?? theme.colorScheme.primary;

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
      ..color = color.withOpacity(0.85)
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

class _BlurredOrb extends StatelessWidget {
  const _BlurredOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
