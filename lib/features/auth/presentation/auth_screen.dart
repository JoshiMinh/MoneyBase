import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({required this.onLogin, super.key});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final body = isWide
            ? Row(
                children: [
                  const Expanded(child: _AuthMarketingPanel()),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 64,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _AuthCard(onLogin: onLogin),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _AuthCard(onLogin: onLogin),
                  ),
                ),
              );

        return Scaffold(
          appBar: isWide ? null : AppBar(title: const Text('MoneyBase Login')),
          body: body,
        );
      },
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.savings_outlined,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text('Sign in to MoneyBase', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Continue with your existing account to sync wallets, budgets, and transactions '
              'across Android and the new web experience.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(value: true, onChanged: (_) {}),
                const SizedBox(width: 8),
                const Expanded(child: Text('Stay signed in on this device')),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onLogin,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Continue'),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Forgot password?'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthMarketingPanel extends StatelessWidget {
  const _AuthMarketingPanel();

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.secondary,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MoneyBase',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Take control of your finances everywhere.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: const [
                  _MarketingBullet(
                    icon: Icons.dashboard_customize_outlined,
                    text:
                        'Dashboard parity with the Android Compose experience.',
                  ),
                  _MarketingBullet(
                    icon: Icons.sync_alt_outlined,
                    text:
                        'Live sync for wallets, categories, and transactions.',
                  ),
                  _MarketingBullet(
                    icon: Icons.palette_outlined,
                    text:
                        'Dynamic theming that respects your MoneyBase palette.',
                  ),
                  _MarketingBullet(
                    icon: Icons.shield_outlined,
                    text: 'Secure authentication backed by Firebase.',
                  ),
                ],
              ),
            ),
          ],
        ),
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
          Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
