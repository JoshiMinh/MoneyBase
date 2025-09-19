import 'package:flutter/material.dart';

import '../features/app_shell/presentation/app_shell.dart';
import '../features/auth/presentation/auth_screen.dart';
import 'theme/theme.dart';

class MoneyBaseApp extends StatefulWidget {
  const MoneyBaseApp({super.key});

  @override
  State<MoneyBaseApp> createState() => _MoneyBaseAppState();
}

class _MoneyBaseAppState extends State<MoneyBaseApp> {
  late final ThemeController _themeController;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  void _onLogin() {
    setState(() => _authenticated = true);
  }

  void _onLogout() {
    setState(() => _authenticated = false);
  }

  @override
  Widget build(BuildContext context) {
    return ThemeControllerProvider(
      notifier: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          final theme = MoneyBaseTheme.buildTheme(
            palette: _themeController.palette,
            darkMode: _themeController.darkMode,
            customPrimary: _themeController.customPrimary,
          );

          return MaterialApp(
            title: 'MoneyBase',
            theme: theme,
            debugShowCheckedModeBanner: false,
            home: _authenticated
                ? AppShell(onLogout: _onLogout)
                : AuthScreen(onLogin: _onLogin),
          );
        },
      ),
    );
  }
}
