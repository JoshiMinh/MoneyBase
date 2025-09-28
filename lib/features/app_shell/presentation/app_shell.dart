import 'package:flutter/material.dart';

import '../../home/presentation/ai_assistant_sheet.dart';
import '../../home/presentation/home_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';

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
    BuildContext context,
    _NavigationDestination destination,
  ) {
    if (destination.path == ModalRoute.of(context)?.settings.name) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(destination.path);
  }

  _NavigationDestination? get _currentDestination {
    switch (page) {
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
    _NavigationDestination? destination,
  ) {
    if (destination == _NavigationDestination.settings) {
      return null;
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
        final useRail = constraints.maxWidth >= 900;
        final theme = Theme.of(context);
        final floatingActions = _buildFloatingActions(
          context,
          currentDestination,
        );

        if (useRail) {
          final railTheme = NavigationRailTheme.of(context);
          final railBackground =
              railTheme.backgroundColor ??
              (theme.brightness == Brightness.dark
                  ? const Color(0xFF0F0F0F)
                  : const Color(0xFFF9F9F9));
          final dividerColor = theme.colorScheme.outlineVariant.withOpacity(
            0.4,
          );

          return Scaffold(
            backgroundColor: theme.colorScheme.background,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: floatingActions,
            body: Row(
              children: [
                Container(
                  color: railBackground,
                  child: _SidebarNavigation(
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
                    child: KeyedSubtree(key: ValueKey(page), child: body),
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

enum _NavigationDestination {
  home(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    path: '/',
  ),
  budgets(
    label: 'Budgets',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
    path: '/budgets',
  ),
  shoppingList(
    label: 'Shopping List',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
    path: '/shopping',
  ),
  settings(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    path: '/settings',
    isSecondary: true,
  );

  const _NavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    this.isSecondary = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final bool isSecondary;
}

class _SidebarNavigation extends StatelessWidget {
  const _SidebarNavigation({
    required this.destinations,
    required this.secondaryDestinations,
    required this.selected,
    required this.onSelect,
  });

  final List<_NavigationDestination> destinations;
  final List<_NavigationDestination> secondaryDestinations;
  final _NavigationDestination? selected;
  final ValueChanged<_NavigationDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'app_icon.ico',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            for (var i = 0; i < destinations.length; i++) ...[
              _SidebarItem(
                destination: destinations[i],
                selected: destinations[i] == selected,
                onTap: () => onSelect(destinations[i]),
              ),
              if (i != destinations.length - 1) const SizedBox(height: 12),
            ],
            const Spacer(),
            const _PremiumPlaceholderButton(),
            const SizedBox(height: 12),
            for (var i = 0; i < secondaryDestinations.length; i++) ...[
              _SidebarItem(
                destination: secondaryDestinations[i],
                selected: secondaryDestinations[i] == selected,
                onTap: () => onSelect(secondaryDestinations[i]),
              ),
              if (i != secondaryDestinations.length - 1)
                const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = selected
        ? colorScheme.primary.withOpacity(0.12)
        : Colors.transparent;
    final iconColor = selected ? colorScheme.primary : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withOpacity(0.28)
                : Colors.transparent,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(destination.icon, color: iconColor),
                  const SizedBox(height: 6),
                  Text(
                    destination.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumPlaceholderButton extends StatelessWidget {
  const _PremiumPlaceholderButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Tooltip(
        message: 'Premium (coming soon)',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: iconColor.withOpacity(0.28)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_outlined, color: iconColor),
                    const SizedBox(height: 6),
                    Text(
                      'Premium',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
