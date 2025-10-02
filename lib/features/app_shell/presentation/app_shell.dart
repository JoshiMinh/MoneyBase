import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../home/presentation/ai_assistant_sheet.dart';
import '../../home/presentation/home_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';

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
  static const _railExpandedStorageKey = 'navigation.railExpanded';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SharedPreferences? _preferences;
  bool? _railExpanded;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRailExpandedPreference());
  }

  Future<void> _loadRailExpandedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getBool(_railExpandedStorageKey);
    if (!mounted) return;

    setState(() {
      _preferences = prefs;
      _railExpanded = storedValue;
    });
  }

  Future<void> _saveRailExpanded(bool value) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.setBool(_railExpandedStorageKey, value);
    _preferences = prefs;
  }

  void _updateRailExpanded(bool value) {
    setState(() {
      _railExpanded = value;
    });
    unawaited(_saveRailExpanded(value));
  }

  void _toggleRailExpanded(bool current) {
    _updateRailExpanded(!current);
  }

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

  PreferredSizeWidget _buildTopAppBar({
    required BuildContext context,
    required bool isMobile,
    required bool railExpanded,
  }) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(
          isMobile
              ? Icons.menu
              : (railExpanded ? Icons.menu_open : Icons.menu),
        ),
        tooltip: isMobile
            ? 'Open navigation menu'
            : (railExpanded ? 'Collapse navigation' : 'Expand navigation'),
        onPressed: () {
          if (isMobile) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            _toggleRailExpanded(railExpanded);
          }
        },
      ),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'icon.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'MoneyBase',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        final isMobile = constraints.maxWidth < 600;
        final isDesktop = constraints.maxWidth > 1024;
        final theme = Theme.of(context);
        final floatingActions = _buildFloatingActions(
          context,
          currentDestination,
        );
        final backgroundColor = theme.colorScheme.background;
        final railExtended = _railExpanded ?? isDesktop;

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

        final railTheme = NavigationRailTheme.of(context);
        final railBackground = railTheme.backgroundColor ??
            (theme.brightness == Brightness.dark
                ? const Color(0xFF0F0F0F)
                : const Color(0xFFF9F9F9));
        final dividerColor = theme.colorScheme.outlineVariant.withOpacity(0.4);

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: backgroundColor,
          appBar: _buildTopAppBar(
            context: context,
            isMobile: false,
            railExpanded: railExtended,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: floatingActions,
          body: Row(
            children: [
              Container(
                color: railBackground,
                child: _ResponsiveNavigationRail(
                  destinations: primaryDestinations,
                  secondaryDestinations: secondaryDestinations,
                  selected: currentDestination,
                  extended: railExtended,
                  onSelect: (destination) =>
                      _handleDestinationSelected(context, destination),
                ),
              ),
              VerticalDivider(width: 1, color: dividerColor),
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

class _ResponsiveNavigationRail extends StatelessWidget {
  const _ResponsiveNavigationRail({
    required this.destinations,
    required this.secondaryDestinations,
    required this.selected,
    required this.extended,
    required this.onSelect,
  });

  final List<_NavigationDestination> destinations;
  final List<_NavigationDestination> secondaryDestinations;
  final _NavigationDestination? selected;
  final bool extended;
  final ValueChanged<_NavigationDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    final allDestinations = <_NavigationDestination>[
      ...destinations,
      ...secondaryDestinations,
    ];
    final selectedIndex = selected != null
        ? allDestinations.indexOf(selected!)
        : 0;
    final normalizedSelectedIndex =
        selectedIndex >= 0 ? selectedIndex : 0;

    return NavigationRail(
      extended: extended,
      minExtendedWidth: 220,
      labelType: NavigationRailLabelType.none,
      selectedIndex: normalizedSelectedIndex,
      onDestinationSelected: (index) {
        if (index < 0 || index >= allDestinations.length) {
          return;
        }
        onSelect(allDestinations[index]);
      },
      destinations: [
        for (final destination in allDestinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
      ],
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: _RailHeader(extended: extended),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _RailPremiumPlaceholder(extended: extended),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'icon.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          if (extended) ...[
            const SizedBox(height: 12),
            Text(
              'MoneyBase',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RailPremiumPlaceholder extends StatelessWidget {
  const _RailPremiumPlaceholder({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.primary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 12),
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
              padding: EdgeInsets.symmetric(
                horizontal: extended ? 16 : 12,
                vertical: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: extended
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium_outlined, color: iconColor),
                  const SizedBox(height: 8),
                  Text(
                    'Premium',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: extended ? TextAlign.start : TextAlign.center,
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

class _ShellNavigationDrawer extends StatelessWidget {
  const _ShellNavigationDrawer({
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
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'icon.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MoneyBase',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final destination in destinations)
                    _DrawerDestinationTile(
                      destination: destination,
                      selected: destination == selected,
                      onTap: () => onSelect(destination),
                    ),
                  if (destinations.isNotEmpty && secondaryDestinations.isNotEmpty)
                    const Divider(),
                  _DrawerPremiumPlaceholder(),
                  if (secondaryDestinations.isNotEmpty) const Divider(),
                  for (final destination in secondaryDestinations)
                    _DrawerDestinationTile(
                      destination: destination,
                      selected: destination == selected,
                      onTap: () => onSelect(destination),
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

class _DrawerDestinationTile extends StatelessWidget {
  const _DrawerDestinationTile({
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
    final activeColor = colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          selected ? destination.selectedIcon : destination.icon,
          color: selected ? activeColor : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          destination.label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: selected ? activeColor : null,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: selected,
        selectedTileColor: activeColor.withOpacity(0.12),
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
      ),
    );
  }
}

class _DrawerPremiumPlaceholder extends StatelessWidget {
  const _DrawerPremiumPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_outlined, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Premium',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
