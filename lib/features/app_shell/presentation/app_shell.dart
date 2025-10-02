import 'dart:ui';
import 'package:flutter/material.dart';

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
  late AppShellPage _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.page;
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

  Widget _buildPage() {
    switch (_selected) {
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final useSidebar = constraints.maxWidth >= 768;
      final body = _buildPage();

      return Scaffold(
        body: Row(
          children: [
            if (useSidebar)
              _SidebarNavigation(
                selected: _selected,
                onSelect: (page) {
                  setState(() => _selected = page);
                },
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(key: ValueKey(_selected), child: body),
              ),
            ),
          ],
        ),
        bottomNavigationBar: useSidebar
            ? null
            : NavigationBar(
                selectedIndex: AppShellPage.values.indexOf(_selected),
                onDestinationSelected: (index) {
                  setState(() => _selected = AppShellPage.values[index]);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                    label: 'Budgets',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.shopping_cart_outlined),
                    selectedIcon: Icon(Icons.shopping_cart_rounded),
                    label: 'Shopping',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
        floatingActionButton: _selected == AppShellPage.settings
            ? null
            : SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    });
  }
}

// ======================= Sidebar đẹp =========================

class _SidebarNavigation extends StatefulWidget {
  const _SidebarNavigation({
    required this.selected,
    required this.onSelect,
  });

  final AppShellPage selected;
  final ValueChanged<AppShellPage> onSelect;

  @override
  State<_SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<_SidebarNavigation> {
  bool _isExpanded = true;

  void _toggleSidebar() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: _isExpanded ? 240 : 72,
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.95),
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: SafeArea(
            child: Column(
              children: [
                // Header có nút toggle
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: _isExpanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: AnimatedRotation(
                          turns: _isExpanded ? 0 : 0.25,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(Icons.menu),
                        ),
                        onPressed: _toggleSidebar,
                        tooltip: _isExpanded ? 'Collapse' : 'Expand',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                      ),
                      // Title fade/slide in/out
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) {
                          final offsetAnim = Tween<Offset>(
                                  begin: const Offset(-0.15, 0),
                                  end: Offset.zero)
                              .animate(CurvedAnimation(
                                  parent: anim, curve: Curves.easeInOut));
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: offsetAnim,
                              child: child,
                            ),
                          );
                        },
                        child: _isExpanded
                            ? Padding(
                                key: const ValueKey('sidebar-title'),
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  'MoneyBase',
                                  style:
                                      theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              )
                            : const SizedBox(
                                key: ValueKey('sidebar-title-empty'),
                                width: 0,
                                height: 0,
                              ),
                      ),
                    ],
                  ),
                ),

                const Divider(),
                const SizedBox(height: 16),

                // Items
                _SidebarItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  isSelected: widget.selected == AppShellPage.home,
                  isExpanded: _isExpanded,
                  onTap: () => widget.onSelect(AppShellPage.home),
                ),
                _SidebarItem(
                  label: 'Budgets',
                  icon: Icons.account_balance_wallet_outlined,
                  selectedIcon: Icons.account_balance_wallet_rounded,
                  isSelected: widget.selected == AppShellPage.budgets,
                  isExpanded: _isExpanded,
                  onTap: () => widget.onSelect(AppShellPage.budgets),
                ),
                _SidebarItem(
                  label: 'Shopping',
                  icon: Icons.shopping_cart_outlined,
                  selectedIcon: Icons.shopping_cart_rounded,
                  isSelected: widget.selected == AppShellPage.shopping,
                  isExpanded: _isExpanded,
                  onTap: () => widget.onSelect(AppShellPage.shopping),
                ),

                const Spacer(),

                _PremiumPlaceholderButton(isExpanded: _isExpanded),
                const SizedBox(height: 12),

                _SidebarItem(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  isSelected: widget.selected == AppShellPage.settings,
                  isExpanded: _isExpanded,
                  onTap: () => widget.onSelect(AppShellPage.settings),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Sidebar item với hover effect + fade+slide label
class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
    required this.isExpanded,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isExpanded;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? colors.primaryContainer
              : _isHovered
                  ? colors.surfaceVariant.withOpacity(0.6)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Icon(
                widget.isSelected ? widget.selectedIcon : widget.icon,
                color: widget.isSelected
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
              // space between icon and label (kept even when collapsed for consistent look)
              const SizedBox(width: 12),
              // label area (animated)
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) {
                    final offsetAnim = Tween<Offset>(
                            begin: const Offset(-0.12, 0), end: Offset.zero)
                        .animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeInOut));
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: offsetAnim, child: child),
                    );
                  },
                  child: widget.isExpanded
                      ? Text(
                          widget.label,
                          key: ValueKey('label-${widget.label}'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: widget.isSelected
                                ? colors.onPrimaryContainer
                                : colors.onSurfaceVariant,
                            fontWeight: widget.isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : SizedBox(
                          key: ValueKey('label-empty-${widget.label}'),
                          width: 0,
                          height: 0,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Nút Premium Gradient (giữ y hệt)
class _PremiumPlaceholderButton extends StatelessWidget {
  const _PremiumPlaceholderButton({required this.isExpanded});
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withOpacity(0.2),
            colors.tertiary.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: colors.primary),
          if (isExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Go Premium',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: colors.primary)),
                  Text('Coming soon',
                      style: TextStyle(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
