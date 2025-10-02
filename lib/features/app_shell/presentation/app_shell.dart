import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moneybase/app/theme/theme.dart';
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

  Widget _buildProfileAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColors = context.themeColors;
    final backgroundColor = themeColors.secondaryAccent.withOpacity(
      isDark ? 0.24 : 0.12,
    );

    return CircleAvatar(
      radius: 18,
      backgroundColor: backgroundColor,
      child: Icon(
        Icons.person_outline,
        color: themeColors.secondaryAccent,
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
      foregroundColor: foregroundColor,
      iconTheme: IconThemeData(color: foregroundColor),
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
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildProfileAvatar(context),
        ),
      ],
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
        final backgroundColor = theme.scaffoldBackgroundColor;
        final railExtended = _railExpanded ?? isDesktop;
        final profileAvatar = _buildProfileAvatar(context);

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
          body: Row(
            children: [
              _ResponsiveNavigationRail(
                destinations: primaryDestinations,
                secondaryDestinations: secondaryDestinations,
                selected: currentDestination,
                extended: railExtended,
                onSelect: (destination) =>
                    _handleDestinationSelected(context, destination),
                onToggleExtended: () => _toggleRailExpanded(railExtended),
                profileAvatar: profileAvatar,
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
    label: 'Shopping',
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
    this.badgeCount,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final bool isSecondary;
  final int? badgeCount;
}

class _ResponsiveNavigationRail extends StatelessWidget {
  const _ResponsiveNavigationRail({
    required this.destinations,
    required this.secondaryDestinations,
    required this.selected,
    required this.extended,
    required this.onSelect,
    required this.onToggleExtended,
    required this.profileAvatar,
  });

  static const _animationDuration = Duration(milliseconds: 250);

  final List<_NavigationDestination> destinations;
  final List<_NavigationDestination> secondaryDestinations;
  final _NavigationDestination? selected;
  final bool extended;
  final ValueChanged<_NavigationDestination> onSelect;
  final VoidCallback onToggleExtended;
  final Widget profileAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = context.themeColors;
    final background = themeColors.surfaceBackground;
    final borderColor = themeColors.surfaceBorder;

    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeInOut,
      width: extended ? 260 : 88,
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        left: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment:
                extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: extended ? 20 : 0),
                child: _RailHeader(
                  extended: extended,
                  onToggleExtended: onToggleExtended,
                  profileAvatar: profileAvatar,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: extended ? 12 : 0),
                  child: _RailDestinationList(
                    destinations: destinations,
                    extended: extended,
                    selected: selected,
                    onSelect: onSelect,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 0),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: extended
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    for (final destination in secondaryDestinations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RailDestinationTile(
                          destination: destination,
                          extended: extended,
                          isSelected: destination == selected,
                          onTap: () => onSelect(destination),
                        ),
                      ),
                    _RailPremiumButton(extended: extended),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader({
    required this.extended,
    required this.onToggleExtended,
    required this.profileAvatar,
  });

  final bool extended;
  final VoidCallback onToggleExtended;
  final Widget profileAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = context.themeColors;
    final textColor = themeColors.primaryText;
    final toggleIcon = extended ? Icons.chevron_left : Icons.chevron_right;
    final toggleTooltip =
        extended ? 'Collapse navigation' : 'Expand navigation';

    Widget buildToggleButton() {
      return IconButton(
        icon: Icon(toggleIcon, color: themeColors.mutedText),
        tooltip: toggleTooltip,
        onPressed: onToggleExtended,
        visualDensity: VisualDensity.compact,
      );
    }

    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'icon.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );

    if (!extended) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logo,
          const SizedBox(height: 12),
          buildToggleButton(),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            width: 36,
            child: profileAvatar,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logo,
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MoneyBase',
                textAlign: TextAlign.left,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
        buildToggleButton(),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          width: 36,
          child: profileAvatar,
        ),
      ],
    );
  }
}

class _RailDestinationList extends StatelessWidget {
  const _RailDestinationList({
    required this.destinations,
    required this.extended,
    required this.selected,
    required this.onSelect,
  });

  final List<_NavigationDestination> destinations;
  final bool extended;
  final _NavigationDestination? selected;
  final ValueChanged<_NavigationDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment:
            extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          for (final destination in destinations)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RailDestinationTile(
                destination: destination,
                extended: extended,
                isSelected: destination == selected,
                onTap: () => onSelect(destination),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailDestinationTile extends StatelessWidget {
  const _RailDestinationTile({
    required this.destination,
    required this.extended,
    required this.isSelected,
    required this.onTap,
  });

  static const _indicatorWidth = 3.0;
  static const _animationDuration = Duration(milliseconds: 220);

  final _NavigationDestination destination;
  final bool extended;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColors = context.themeColors;
    final accent = themeColors.primaryAccent;
    final inactiveTextColor = themeColors.mutedText;
    final iconColor = isSelected ? accent : inactiveTextColor;
    final textStyle = theme.textTheme.titleMedium?.copyWith(
      color: isSelected ? accent : inactiveTextColor,
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
    );
    final tooltipMessage = destination.label;
    final iconWidget = _DestinationIcon(
      destination: destination,
      iconColor: iconColor,
      isSelected: isSelected,
    );

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor:
            themeColors.secondaryAccent.withOpacity(isDark ? 0.18 : 0.1),
        splashColor: accent.withOpacity(0.18),
        highlightColor: accent.withOpacity(isDark ? 0.24 : 0.14),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: extended ? 12 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withOpacity(isDark ? 0.24 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: _animationDuration,
                curve: Curves.easeInOut,
                height: 36,
                width: _indicatorWidth,
                decoration: BoxDecoration(
                  color: isSelected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(_indicatorWidth),
                ),
              ),
              const SizedBox(width: 12),
              iconWidget,
              if (extended) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: _animationDuration,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Align(
                      key: ValueKey<bool>(isSelected),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        destination.label,
                        textAlign: TextAlign.left,
                        style: textStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (extended) {
      return tile;
    }

    return Tooltip(
      message: tooltipMessage,
      waitDuration: const Duration(milliseconds: 400),
      preferBelow: false,
      child: tile,
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  const _DestinationIcon({
    required this.destination,
    required this.iconColor,
    required this.isSelected,
  });

  final _NavigationDestination destination;
  final Color iconColor;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      isSelected ? destination.selectedIcon : destination.icon,
      color: iconColor,
      size: 24,
    );
    final badgeCount = destination.badgeCount ?? 0;
    if (badgeCount <= 0) {
      return icon;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -4,
          child: _NotificationBadge(count: badgeCount),
        ),
      ],
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayCount = count > 9 ? '9+' : '$count';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.onError, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
        child: Text(
          displayCount,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onError,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RailPremiumButton extends StatelessWidget {
  const _RailPremiumButton({required this.extended});

  static const _animationDuration = Duration(milliseconds: 220);

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColors = context.themeColors;
    final accent = themeColors.primaryAccent;

    return Tooltip(
      message: 'Premium',
      waitDuration: const Duration(milliseconds: 400),
      triggerMode:
          extended ? TooltipTriggerMode.manual : TooltipTriggerMode.longPress,
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: Curves.easeInOut,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: accent,
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(isDark ? 0.4 : 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withOpacity(0.12),
            highlightColor: Colors.white.withOpacity(0.08),
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: extended ? 16 : 0,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment:
                    extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    color: Colors.white,
                  ),
                  if (extended) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Go Premium',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
    final themeColors = context.themeColors;
    final backgroundColor = themeColors.surfaceBackground;
    final dividerColor = themeColors.surfaceBorder;
    final titleColor = themeColors.primaryText;

    return Drawer(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'icon.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'MoneyBase',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final destination in destinations)
                    _DrawerDestinationTile(
                      destination: destination,
                      selected: destination == selected,
                      onTap: () => onSelect(destination),
                    ),
                ],
              ),
            ),
            if (destinations.isNotEmpty && secondaryDestinations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  color: dividerColor,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final destination in secondaryDestinations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DrawerDestinationTile(
                        destination: destination,
                        selected: destination == selected,
                        onTap: () => onSelect(destination),
                      ),
                    ),
                  _DrawerPremiumButton(),
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
    final isDark = theme.brightness == Brightness.dark;
    final themeColors = context.themeColors;
    final activeColor = themeColors.primaryAccent;
    final inactiveColor = themeColors.mutedText;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      hoverColor:
          themeColors.secondaryAccent.withOpacity(isDark ? 0.2 : 0.12),
      splashColor: activeColor.withOpacity(0.18),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? activeColor.withOpacity(isDark ? 0.28 : 0.12)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            _DestinationIcon(
              destination: destination,
              iconColor: selected ? activeColor : inactiveColor,
              isSelected: selected,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                destination.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? activeColor : inactiveColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerPremiumButton extends StatelessWidget {
  const _DrawerPremiumButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeColors = context.themeColors;
    final accent = themeColors.primaryAccent;

    return FilledButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.workspace_premium_outlined),
      label: const Text('Go Premium'),
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Colors.white.withOpacity(isDark ? 0.16 : 0.08),
          ),
        ),
      ),
    );
  }
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
