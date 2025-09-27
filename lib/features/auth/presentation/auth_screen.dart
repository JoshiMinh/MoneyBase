import 'package:flutter/material.dart';

import '../../common/presentation/moneybase_shell.dart';
import 'widgets/auth_card.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, this.onLoginSuccess});

  final VoidCallback? onLoginSuccess;

  @override
  Widget build(BuildContext context) {
    return MoneyBaseScaffold(
      maxContentWidth: 1200,
      widePadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 64),
      builder: (context, layout) {
        final authCard = AuthCard(
          onLoginSuccess: onLoginSuccess,
          isWide: layout.isWide,
        );

        if (layout.isWide) {
          return Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 32),
                  child: _AuthMarketingPanel(),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: authCard,
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.topCenter, child: authCard),
            const SizedBox(height: 24),
            const _AuthMarketingPanel(compact: true),
          ],
        );
      },
    );
  }
}

class _AuthMarketingPanel extends StatelessWidget {
  const _AuthMarketingPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final primaryTextColor = isLightMode ? Colors.black : Colors.white;
    final secondaryTextColor = primaryTextColor.withOpacity(0.85);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 28)
        : const EdgeInsets.symmetric(horizontal: 48, vertical: 64);
    final borderRadius = compact ? 28.0 : 32.0;
    final bulletSpacing = compact ? 16.0 : 20.0;
    const bullets = [
      _MarketingBullet(
        icon: Icons.auto_graph_outlined,
        text: 'Visualize spending trends with live-updating charts.',
      ),
      _MarketingBullet(
        icon: Icons.verified_user_outlined,
        text: 'Enterprise-grade security powered by Firebase Auth.',
      ),
      _MarketingBullet(
        icon: Icons.devices_other_outlined,
        text: 'Optimized layouts tailored to desktop, tablet, and mobile.',
      ),
      _MarketingBullet(
        icon: Icons.smart_toy_outlined,
        text: 'AI budgeting assistance to answer finance questions fast.',
      ),
    ];

    return MoneyBaseFrostedPanel(
      padding: padding,
      borderRadius: borderRadius,
      backgroundOpacity: 0.12,
      borderOpacity: 0.18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MoneyBase',
            style: theme.textTheme.displaySmall?.copyWith(
              color: primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All-new everywhere access.',
            style: theme.textTheme.titleLarge?.copyWith(
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Plan budgets, review reports, and reconcile your accounts seamlessly between web and Android with a refreshed design.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 32),
          for (var i = 0; i < bullets.length; i++) ...[
            bullets[i],
            if (i != bullets.length - 1) SizedBox(height: bulletSpacing),
          ],
        ],
      ),
    );
  }
}

class _MarketingBullet extends StatelessWidget {
  const _MarketingBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final iconColor = isLightMode ? Colors.black87 : Colors.white;
    final textColor =
        (isLightMode ? Colors.black : Colors.white).withOpacity(0.85);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
