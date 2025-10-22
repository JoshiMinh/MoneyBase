import 'package:flutter/material.dart';
import 'package:moneybase/app/theme/theme.dart';

import '../../common/presentation/moneybase_shell.dart';
import '../../home/presentation/ai_assistant_sheet.dart';
import '../../home/presentation/home_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';

part 'widgets/desktop_ai_assistant_button.dart';
part 'widgets/shell_navigation_drawer.dart';
part 'widgets/shell_navigation_rail.dart';
part 'widgets/shell_premium_screen.dart';

enum AppShellPage { home, budgets, shopping, settings }

class AppShell extends StatefulWidget {
  const AppShell({
    required this.onLogout,
    this.page = AppShellPage.home,
    super.key,
  });

  final VoidCallback onLogout;
  final AppShellPage page;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _handleDestinationSelected(
    BuildContext context,
    _NavigationDestination destination,
  ) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (destination.path == currentRoute) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(destination.path);
  }

  _NavigationDestination? get _currentDestination {
    switch (widget.page) {
      case AppShellPage.home:
        return _NavigationDestination.home;
      case AppShellPage.budgets:
        return _NavigationDestination.budgets;
      case AppShellPage.shopping:
        return _NavigationDestination.shoppingList;
      case AppShellPage.settings:
        return _NavigationDestination.settings;
    }
  }

  Widget _buildPageBody(BuildContext context) {
    switch (widget.page) {
      case AppShellPage.home:
        return HomeScreen(
          onViewReports: () => _openReports(context),
          onViewTransactions: () => _openTransactions(context),
        );
      case AppShellPage.budgets:
        return HomeScreen(
          showBudgetsOnly: true,
          onViewReports: () => _openReports(context),
          onViewTransactions: () => _openTransactions(context),
        );
      case AppShellPage.shopping:
        return const ShoppingListScreen();
      case AppShellPage.settings:
        return SettingsScreen(onLogout: widget.onLogout);
    }
  }

  void _openAddTransaction(BuildContext context) {
    Navigator.of(context).pushNamed('/add');
  }

  void _openReports(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
    );
  }

  void _openTransactions(BuildContext context) {
    Navigator.of(context).pushNamed('/transactions');
  }

  void _openAiAssistant(BuildContext context) {
    Navigator.of(context).pushNamed(_AppShellRoutes.assistant);
  }

  Widget? _buildFloatingActions(
    BuildContext context,
    _NavigationDestination? destination, {
    required bool isMobile,
  }) {
    if (destination == _NavigationDestination.settings) {
      return null;
    }

    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 640 ? 32.0 : 20.0;

    if (!isMobile) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: FloatingActionButton.extended(
            heroTag: 'addTransactionFab',
            onPressed: () => _openAddTransaction(context),
            icon: const Icon(Icons.add),
            label: const Text('Add transaction'),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          children: [
            FloatingActionButton(
              heroTag: 'aiChatFab',
              onPressed: () => _openAiAssistant(context),
              child: const Icon(Icons.smart_toy_outlined),
            ),
            const Spacer(),
            FloatingActionButton.extended(
              heroTag: 'addTransactionFab',
              onPressed: () => _openAddTransaction(context),
              icon: const Icon(Icons.add),
              label: const Text('Add transaction'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar({
    required BuildContext context,
    required bool isMobile,
    required bool railExpanded,
  }) {
    final theme = Theme.of(context);
    final themeColors = context.themeColors;
    final foregroundColor = themeColors.primaryText;
    final surfaceColor = themeColors.surfaceElevated;

    return AppBar(
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      centerTitle: true,
      foregroundColor: foregroundColor,
      iconTheme: IconThemeData(color: foregroundColor),
      leading: isMobile
          ? IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Open navigation menu',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/icon.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: isMobile || railExpanded
                ? Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'MoneyBase',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: foregroundColor,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      actions: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _NavigationDestination.values;
    final primaryDestinations = destinations
        .where((destination) => !destination.isSecondary)
        .toList();
    final secondaryDestinations = destinations
        .where((destination) => destination.isSecondary)
        .toList();
    final currentDestination = _currentDestination;
    final body = _buildPageBody(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final theme = Theme.of(context);
        final floatingActions = _buildFloatingActions(
          context,
          currentDestination,
          isMobile: isMobile,
        );
        final backgroundColor = theme.scaffoldBackgroundColor;
        const railExtended = true;

        if (isMobile) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: backgroundColor,
            appBar: _buildTopAppBar(
              context: context,
              isMobile: true,
              railExpanded: false,
            ),
            drawer: _ShellNavigationDrawer(
              destinations: primaryDestinations,
              secondaryDestinations: secondaryDestinations,
              selected: currentDestination,
              onSelect: (destination) =>
                  _handleDestinationSelected(context, destination),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: floatingActions,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(widget.page),
                child: body,
              ),
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: backgroundColor,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: floatingActions,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  _ResponsiveNavigationRail(
                    destinations: primaryDestinations,
                    secondaryDestinations: secondaryDestinations,
                    selected: currentDestination,
                    extended: railExtended,
                    onSelect: (destination) =>
                        _handleDestinationSelected(context, destination),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(
                        key: ValueKey(widget.page),
                        child: body,
                      ),
                    ),
                  ),
                ],
              ),
              if (currentDestination != _NavigationDestination.settings)
                _DesktopAiAssistantButton(
                  onPressed: () => _openAiAssistant(context),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AppShellRoutes {
  static const home = '/';
  static const budgets = '/budgets';
  static const shopping = '/shopping';
  static const settings = '/settings';
  static const assistant = '/assistant';
}

enum _NavigationDestination {
  home(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    path: _AppShellRoutes.home,
  ),
  budgets(
    label: 'Budgets',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
    path: _AppShellRoutes.budgets,
  ),
  shoppingList(
    label: 'Shopping',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
    path: _AppShellRoutes.shopping,
  ),
  settings(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    path: _AppShellRoutes.settings,
    isSecondary: true,
  );

  const _NavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    this.isSecondary = false,
    this.badgeCount,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final bool isSecondary;
  final int? badgeCount;
}

extension _ThemeColorsContext on BuildContext {
  MoneyBaseThemeColors get themeColors {
    final theme = Theme.of(this);
    return theme.extension<MoneyBaseThemeColors>() ??
        MoneyBaseThemeColors.fallback(
          darkMode: theme.brightness == Brightness.dark,
        );
  }
}
