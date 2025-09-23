import 'package:flutter/material.dart';

import '../../add_transaction/presentation/add_transaction_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';
import '../../transactions/presentation/transactions_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.onLogout, super.key});

  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _handleTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _openAddTransaction() {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const AddTransactionScreen()),
    );
  }

  void _openReports() {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
    );
  }

  void _openTransactions() {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const TransactionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _NavigationDestination.values;
    final pages = <Widget>[
      HomeScreen(
        onAddTransaction: _openAddTransaction,
        onViewReports: _openReports,
        onViewTransactions: _openTransactions,
      ),
      const ShoppingListScreen(),
      SettingsScreen(onLogout: widget.onLogout),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;
        final railExtended = constraints.maxWidth >= 1200;

        final theme = Theme.of(context);

        if (useRail) {
          final railTheme = NavigationRailTheme.of(context);
          final railBackground = railTheme.backgroundColor ??
              (theme.brightness == Brightness.dark
                  ? const Color(0xFF0F0F0F)
                  : const Color(0xFFF9F9F9));
          final dividerColor =
              theme.colorScheme.outlineVariant.withOpacity(0.4);

          return Scaffold(
            backgroundColor: theme.colorScheme.background,
            body: Row(
              children: [
                Container(
                  color: railBackground,
                  child: _AppNavigationRail(
                    destinations: destinations,
                    extended: railExtended,
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _handleTabSelected,
                  ),
                ),
                VerticalDivider(width: 1, color: dividerColor),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(_currentIndex),
                      child: pages[_currentIndex],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final navTheme = NavigationBarTheme.of(context);
        final navBackground = navTheme.backgroundColor ??
            (theme.brightness == Brightness.dark
                ? const Color(0xFF0F0F0F)
                : const Color(0xFFF9F9F9));

        return Scaffold(
          backgroundColor: theme.colorScheme.background,
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            backgroundColor: navBackground,
            surfaceTintColor: Colors.transparent,
            selectedIndex: _currentIndex,
            destinations: [
              for (final destination in destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
            onDestinationSelected: _handleTabSelected,
          ),
        );
      },
    );
  }
}

enum _NavigationDestination {
  home(label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
  shoppingList(
    label: 'Shopping List',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
  ),
  settings(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  const _NavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _AppNavigationRail extends StatelessWidget {
  const _AppNavigationRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.extended,
  });

  final List<_NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final headline = Theme.of(context).textTheme.titleMedium;

    return NavigationRail(
      backgroundColor: Colors.transparent,
      selectedIndex: selectedIndex,
      extended: extended,
      labelType: extended ? null : NavigationRailLabelType.all,
      groupAlignment: -1,
      onDestinationSelected: onDestinationSelected,
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: extended
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'web/favicon.png',
                width: extended ? 44 : 32,
                height: extended ? 44 : 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            if (extended) Text('MoneyBase', style: headline),
          ],
        ),
      ),
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}
