import 'package:flutter/material.dart';

import '../../common/presentation/moneybase_shell.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({required this.onLogin, super.key});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return MoneyBaseScaffold(
      maxContentWidth: 1200,
      widePadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 64),
      builder: (context, layout) {
        final authCard = _AuthCard(
          onLogin: onLogin,
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

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.onLogin, required this.isWide});

  final VoidCallback onLogin;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MoneyBaseFrostedPanel(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 32,
        vertical: isWide ? 48 : 36,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 36,
          offset: Offset(0, 28),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.6),
                child: Icon(
                  Icons.savings_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to sync your budgets and keep your spending on track across Android and the web.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _ThirdPartyButton(
            label: 'Continue with Google',
            icon: Icons.account_circle,
            onPressed: onLogin,
          ),
          const SizedBox(height: 20),
          const _DividerWithText(text: 'or continue with email'),
          const SizedBox(height: 20),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email address'),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: true,
                onChanged: (_) {},
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Keep me signed in',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Forgot password?'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Sign in'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create a MoneyBase account'),
          ),
          const SizedBox(height: 24),
          Text(
            'By continuing you agree to the MoneyBase Terms of Service and acknowledge our Privacy Policy.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthMarketingPanel extends StatelessWidget {
  const _AuthMarketingPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        icon: Icons.palette_outlined,
        text: 'Adaptive theming that reflects your MoneyBase palette.',
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
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All-new everywhere access.',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Plan budgets, review reports, and reconcile your accounts seamlessly between web and Android with a refreshed design.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.85),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThirdPartyButton extends StatelessWidget {
  const _ThirdPartyButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: Colors.white.withOpacity(0.3)),
        foregroundColor: Colors.white,
        textStyle: theme.textTheme.titleMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

class _DividerWithText extends StatelessWidget {
  const _DividerWithText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Divider(color: colorScheme.outlineVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Divider(color: colorScheme.outlineVariant),
        ),
      ],
    );
  }
}
