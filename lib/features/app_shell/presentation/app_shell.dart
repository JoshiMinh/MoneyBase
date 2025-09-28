import 'package:flutter/material.dart';

import '../../home/presentation/ai_assistant_sheet.dart';
import '../../home/presentation/home_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';

import 'app_shell_destinations.dart';
import 'app_shell_page.dart';
import 'widgets/sidebar_navigation.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.onLogout,
    this.page = AppShellPage.home,
    super.key,
  });

  final VoidCallback onLogout;
  final AppShellPage page;

  void _handleDestinationSelected(
    BuildContext context,
    AppShellDestination destination,
  ) {
    if (destination.path == ModalRoute.of(context)?.settings.name) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(destination.path);
  }

  AppShellDestination? get _currentDestination => destinationForPage(page);

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

  Widget? _buildFloatingActions(
    BuildContext context,
    AppShellDestination? destination, {
    required bool useRail,
  }) {
    if (destination?.page == AppShellPage.settings) {
      return null;
    }

    if (useRail) {
      return FloatingActionButton.extended(
        heroTag: 'addTransactionFab',
        onPressed: () => _openAddTransaction(context),
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 640 ? 32.0 : 20.0;

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

  @override
  Widget build(BuildContext context) {
    final destinations = appShellDestinations;
    final primaryDestinations =
        destinations.where((destination) => !destination.isSecondary).toList();
    final secondaryDestinations =
        destinations.where((destination) => destination.isSecondary).toList();
    final currentDestination = _currentDestination;
    final body = _buildPageBody(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;
        final theme = Theme.of(context);
        final floatingActions = _buildFloatingActions(
          context,
          currentDestination,
          useRail: useRail,
        );
        final showSidebarAiFab =
            useRail && currentDestination?.page != AppShellPage.settings;

        if (useRail) {
          final dividerColor = theme.colorScheme.outlineVariant.withOpacity(
            0.4,
          );

          return Scaffold(
            backgroundColor: theme.colorScheme.background,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: floatingActions,
            body: Stack(
              children: [
                Row(
                  children: [
                    Container(
                      color: Colors.transparent,
                      child: SidebarNavigation(
                        destinations: primaryDestinations,
                        secondaryDestinations: secondaryDestinations,
                        selected: currentDestination,
                        onSelect: (destination) =>
                            _handleDestinationSelected(context, destination),
                      ),
                    ),
                    VerticalDivider(width: 1, color: dividerColor),
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
                if (showSidebarAiFab)
                  Positioned(
                    left: kSidebarRailWidth - 36,
                    bottom: 28,
                    child: SidebarFloatingActionButton(
                      onPressed: () => _openAiAssistant(context),
                    ),
                  ),
              ],
            ),
          );
        }

        final navTheme = NavigationBarTheme.of(context);
        final navBackground =
            navTheme.backgroundColor ??
            (theme.brightness == Brightness.dark
                ? const Color(0xFF0F0F0F)
                : const Color(0xFFF9F9F9));

        return Scaffold(
          backgroundColor: theme.colorScheme.background,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: floatingActions,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(key: ValueKey(page), child: body),
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: navBackground,
            surfaceTintColor: Colors.transparent,
            selectedIndex: currentDestination != null
                ? destinations.indexOf(currentDestination)
                : 0,
            destinations: [
              for (final destination in destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
            onDestinationSelected: (index) {
              if (index < 0 || index >= destinations.length) {
                return;
              }
              final destination = destinations[index];
              _handleDestinationSelected(context, destination);
            },
          ),
        );
      },
    );
  }
}
