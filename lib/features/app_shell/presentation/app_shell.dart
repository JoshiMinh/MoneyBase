import 'package:flutter/material.dart';

import '../../add_transaction/presentation/add_transaction_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
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

  void _openAddTransaction() {
    setState(() => _currentIndex = 1);
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
      const AddTransactionScreen(),
      SettingsScreen(onLogout: widget.onLogout),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;
        final railExtended = constraints.maxWidth >= 1200;

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                _AppNavigationRail(
                  destinations: destinations,
                  extended: railExtended,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _handleTabSelected,
                  onAddTransaction: _openAddTransaction,
                ),
                const VerticalDivider(width: 1),
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

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: NavigationBar(
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
  add(
    label: 'Add',
    icon: Icons.add_circle_outline,
    selectedIcon: Icons.add_circle,
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
    required this.onAddTransaction,
    required this.extended,
  });

  final List<_NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddTransaction;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final headline = Theme.of(context).textTheme.titleMedium;

    return NavigationRail(
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
            Icon(Icons.savings, size: extended ? 40 : 28),
            const SizedBox(height: 12),
            if (extended) Text('MoneyBase', style: headline),
          ],
        ),
      ),
      trailing: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: extended
            ? FilledButton.icon(
                onPressed: onAddTransaction,
                icon: const Icon(Icons.add),
                label: const Text('New transaction'),
              )
            : FloatingActionButton.small(
                heroTag: 'rail-add',
                onPressed: onAddTransaction,
                child: const Icon(Icons.add),
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
