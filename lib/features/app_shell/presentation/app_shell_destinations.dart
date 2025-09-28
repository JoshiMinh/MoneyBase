import 'package:flutter/material.dart';

import 'app_shell_page.dart';

class AppShellDestination {
  const AppShellDestination({
    required this.page,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    this.isSecondary = false,
  });

  final AppShellPage page;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final bool isSecondary;
}

const List<AppShellDestination> appShellDestinations = <AppShellDestination>[
  AppShellDestination(
    page: AppShellPage.home,
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    path: '/',
  ),
  AppShellDestination(
    page: AppShellPage.budgets,
    label: 'Budgets',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
    path: '/budgets',
  ),
  AppShellDestination(
    page: AppShellPage.shopping,
    label: 'Shopping List',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
    path: '/shopping',
  ),
  AppShellDestination(
    page: AppShellPage.settings,
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    path: '/settings',
    isSecondary: true,
  ),
];

AppShellDestination? destinationForPage(AppShellPage page) {
  for (final destination in appShellDestinations) {
    if (destination.page == page) {
      return destination;
    }
  }
  return null;
}
