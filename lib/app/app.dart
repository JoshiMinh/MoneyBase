import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/models/transaction.dart';
import '../features/add_transaction/presentation/add_transaction_screen.dart';
import '../features/app_shell/presentation/app_shell.dart';
import '../features/auth/presentation/landing_screen.dart';
import '../features/shopping_list/presentation/shopping_list_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart'
    show TransactionsScreen, TransactionEditorArguments,
        TransactionEditorDialog;
import '../core/services/google_sign_in_service.dart';
import 'theme/theme.dart';

class MoneyBaseApp extends StatefulWidget {
  const MoneyBaseApp({super.key});

  @override
  State<MoneyBaseApp> createState() => _MoneyBaseAppState();
}

class _MoneyBaseAppState extends State<MoneyBaseApp> {
  late final ThemeController _themeController;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return MaterialApp(
                  title: 'MoneyBase',
                  theme: theme,
                  debugShowCheckedModeBanner: false,
                  home: const _AppLoadingScreen(),
                );
              }

              if (snapshot.hasError) {
                return MaterialApp(
                  title: 'MoneyBase',
                  theme: theme,
                  debugShowCheckedModeBanner: false,
                  home: _AppErrorScreen(message: snapshot.error.toString()),
                );
              }

              final user = snapshot.data;
              final authenticated = user != null;

              return MaterialApp(
                key: ValueKey(authenticated),
                navigatorKey: _navigatorKey,
                title: 'MoneyBase',
                theme: theme,
                debugShowCheckedModeBanner: false,
                home: authenticated
                    ? AppShell(onLogout: _onLogout)
                    : const LandingScreen(),
                onGenerateRoute: (settings) =>
                    _onGenerateRoute(settings, authenticated ? user : null),
              );
            },
          );
        },
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings, User? user) {
    final isAuthenticated = user != null;
    final name = settings.name ?? '/';

    if (!isAuthenticated && name != '/landing') {
      return _buildPageRoute(settings, const LandingScreen());
    }

    switch (name) {
      case '/landing':
        return _buildPageRoute(settings, const LandingScreen());
      case '/':
        return _buildPageRoute(
          settings,
          AppShell(onLogout: _onLogout, page: AppShellPage.home),
        );
      case '/budgets':
        return _buildPageRoute(
          settings,
          AppShell(onLogout: _onLogout, page: AppShellPage.budgets),
        );
      case '/shopping':
        return _buildPageRoute(
          settings,
          AppShell(onLogout: _onLogout, page: AppShellPage.shopping),
        );
      case '/settings':
        return _buildPageRoute(
          settings,
          AppShell(onLogout: _onLogout, page: AppShellPage.settings),
        );
      case '/transactions':
        return _buildPageRoute(settings, const TransactionsScreen());
      case '/add':
        return _buildPageRoute(settings, const AddTransactionScreen());
      case '/edit':
        final args = settings.arguments as TransactionEditorArguments?;
        final navigatorContext = _navigatorKey.currentContext;
        if (args == null || navigatorContext == null) {
          return _buildPageRoute(
            settings,
            const _RouteErrorScreen(message: 'Missing transaction data'),
          );
        }

        return DialogRoute<MoneyBaseTransaction>(
          context: navigatorContext,
          settings: settings,
          builder: (_) => TransactionEditorDialog(
            initial: args.transaction,
            wallets: args.wallets,
            categories: args.categories,
          ),
        );
      case '/shopping/list':
        final args = settings.arguments as ShoppingListDetailRouteArgs?;
        if (args == null) {
          return _buildPageRoute(settings, const ShoppingListScreen());
        }

        return _buildPageRoute(
          settings,
          ShoppingListDetailScreen(
            userId: args.userId,
            repository: args.repository,
            initialList: args.initialList,
            onAddItem: args.onAddItem,
            onEditItem: args.onEditItem,
            onDeleteItem: args.onDeleteItem,
            onToggleItem: args.onToggleItem,
            onEditList: args.onEditList,
            onDeleteList: args.onDeleteList,
          ),
        );
      default:
        return _buildPageRoute(
          settings,
          AppShell(onLogout: _onLogout, page: AppShellPage.home),
        );
    }
  }

  MaterialPageRoute<T> _buildPageRoute<T>(
    RouteSettings settings,
    Widget child,
  ) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (_) => child,
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
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
