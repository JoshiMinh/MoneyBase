import 'package:flutter/material.dart';

enum AppShellDestination {
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

  const AppShellDestination({
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

  static Iterable<AppShellDestination> get primary =>
      values.where((destination) => !destination.isSecondary);

  static Iterable<AppShellDestination> get secondary =>
      values.where((destination) => destination.isSecondary);

  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
    );
  }
}
