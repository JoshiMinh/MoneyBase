import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../home/presentation/ai_assistant_sheet.dart';
import '../../home/presentation/home_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';
import 'navigation/app_shell_destination.dart';
import 'navigation/sidebar_navigation.dart';
import 'widgets/app_shell_floating_actions.dart';

enum AppShellPage { home, budgets, shopping, settings }

class AppShell extends StatelessWidget {
  const AppShell({
    required this.onLogout,
    this.page = AppShellPage.home,
    super.key,
  });

  final VoidCallback onLogout;
  final AppShellPage page;

  void _handleDestinationSelected(
      BuildContext context, AppShellDestination destination) {
    if (destination.path == ModalRoute.of(context)?.settings.name) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(destination.path);
  }

  AppShellDestination? get _currentDestination {
    switch (page) {
      case AppShellPage.home:
        return AppShellDestination.home;
      case AppShellPage.budgets:
        return AppShellDestination.budgets;
      case AppShellPage.shopping:
        return AppShellDestination.shoppingList;
      case AppShellPage.settings:
        return AppShellDestination.settings;
    }
  }

  Widget _buildPageBody(BuildContext context) {
    switch (page) {
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
        return SettingsScreen(onLogout: onLogout);
    }
  }

  void _openAddTransaction(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pushNamed('/add');
  }

  void _openReports(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
    );
  }

  void _openTransactions(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pushNamed('/transactions');
  }

  void _openAiAssistant(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiAssistantSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = AppShellDestination.values;
    final primaryDestinations = AppShellDestination.primary.toList();
    final secondaryDestinations = AppShellDestination.secondary.toList();
    final currentDestination = _currentDestination;
    final body = _buildPageBody(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;
        final theme = Theme.of(context);
        final colors = context.moneyBaseColors;
        final shouldShowFloatingActions =
            currentDestination != AppShellDestination.settings;
        final floatingActions = shouldShowFloatingActions
            ? AppShellFloatingActions(
                onAddTransaction: () => _openAddTransaction(context),
                onOpenAssistant: () => _openAiAssistant(context),
                showAssistantButton: !useRail,
              )
            : null;

        if (useRail) {
          final railBackground = Color.alphaBlend(
            colors.glassOverlay,
            colors.surfaceElevated,
          );
          final dividerColor = colors.surfaceBorder;

          return Scaffold(
            backgroundColor: theme.colorScheme.background,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: floatingActions,
            body: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: railBackground,
                    border: Border(
                      right: BorderSide(color: dividerColor),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.surfaceShadow.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SidebarNavigation(
                    destinations: primaryDestinations,
                    secondaryDestinations: secondaryDestinations,
                    selected: currentDestination,
                    onSelect: (destination) =>
                        _handleDestinationSelected(context, destination),
                    onOpenAssistant: () => _openAiAssistant(context),
                  ),
                ),
                Container(width: 1, color: dividerColor),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(page),
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final navBackground = Color.alphaBlend(
          colors.glassOverlay,
          colors.surfaceElevated,
        );
        final navBorder = colors.surfaceBorder;

        return Scaffold(
          backgroundColor: theme.colorScheme.background,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: floatingActions,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(key: ValueKey(page), child: body),
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              color: navBackground,
              border: Border(
                top: BorderSide(color: navBorder),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.surfaceShadow.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              selectedIndex: currentDestination != null
                  ? destinations.indexOf(currentDestination)
                  : 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final destination in destinations)
                  destination.toNavigationDestination(),
              ],
              onDestinationSelected: (index) {
                if (index < 0 || index >= destinations.length) {
                  return;
                }
                final destination = destinations[index];
                _handleDestinationSelected(context, destination);
              },
            ),
          ),
        );
      },
    );
  }
}
