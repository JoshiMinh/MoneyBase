import 'package:flutter/material.dart';

import '../../common/presentation/moneybase_shell.dart';
import '../../../app/theme/theme.dart';
import 'auth_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _openAuth(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => AuthScreen(
          onLoginSuccess: () => Navigator.of(routeContext).maybePop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return MoneyBaseScaffold(
      builder: (context, layout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'web/favicon.png',
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            'MoneyBase',
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Take control of your cashflow with live insights across every device.',
                        style: textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Track spending in real-time, analyse budgets with rich visuals, and manage wallets and categories without ever leaving the dashboard.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.78),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: const [
                          _LandingHighlight(
                            icon: Icons.auto_graph_outlined,
                            title: 'Visual analytics',
                            subtitle:
                                'Understand trends with colourful charts tuned to your theme.',
                          ),
                          _LandingHighlight(
                            icon: Icons.cloud_sync_outlined,
                            title: 'Cloud sync',
                            subtitle:
                                'Your budgets stay in step across Android, web, and desktop.',
                          ),
                          _LandingHighlight(
                            icon: Icons.lock_outline,
                            title: 'Secure by design',
                            subtitle:
                                'Firebase Auth protects every account with modern security.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      FilledButton(
                        onPressed: () => _openAuth(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 18,
                          ),
                          textStyle: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Sign in or create an account'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _openAuth(context),
                        child: const Text('Already exploring? Continue to sign in'),
                      ),
                    ],
                  ),
                ),
                if (layout.isWide) ...[
                  const SizedBox(width: 40),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _PreviewCard(theme: theme),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LandingHighlight extends StatelessWidget {
  const _LandingHighlight({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return MoneyBaseFrostedPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      borderRadius: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 16),
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
                    color: Colors.white.withOpacity(0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.textTheme;

    return MoneyBaseFrostedPanel(
      borderRadius: 36,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'See your budgets come alive',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Switch between red, blue, green, yellow, purple, pink, or gray themes — each one repaints the experience to match your vibe.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme
                        .extension<MoneyBaseThemeColors>()
                        ?.backgroundGradient ??
                    [theme.colorScheme.primary, theme.colorScheme.secondary],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live sync',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MoneyBase keeps every transaction connected to your Firestore data so you never lose track of a penny.',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
