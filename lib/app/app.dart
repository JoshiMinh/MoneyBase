import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/app_shell/presentation/app_shell.dart';
import '../features/auth/presentation/landing_screen.dart';
import '../core/services/google_sign_in_service.dart';
import 'theme/theme.dart';

class MoneyBaseApp extends StatefulWidget {
  const MoneyBaseApp({super.key});

  @override
  State<MoneyBaseApp> createState() => _MoneyBaseAppState();
}

class _MoneyBaseAppState extends State<MoneyBaseApp> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController();
    unawaited(_themeController.loadFromStorage());
    unawaited(googleSignInService.ensureInitialized());
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  void _onLogout() {
    FirebaseAuth.instance.signOut();
    unawaited(googleSignInService.signOut());
  }

  @override
  Widget build(BuildContext context) {
    return ThemeControllerProvider(
      notifier: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          final theme = MoneyBaseTheme.buildTheme(
            darkMode: _themeController.darkMode,
          );

          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final home = _buildHome(snapshot);

              return MaterialApp(
                title: 'MoneyBase',
                theme: theme,
                debugShowCheckedModeBanner: false,
                home: home,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHome(AsyncSnapshot<User?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _AppLoadingScreen();
    }

    if (snapshot.hasError) {
      return _AppErrorScreen(message: snapshot.error.toString());
    }

    final user = snapshot.data;
    if (user != null) {
      return AppShell(onLogout: _onLogout);
    }

    return const LandingScreen();
  }
}

class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _AppErrorScreen extends StatelessWidget {
  const _AppErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
