import 'package:flutter/material.dart';

import 'palettes.dart';

/// Builds themed [ThemeData] instances similar to the Compose `MoneyBaseTheme`.
class MoneyBaseTheme {
  const MoneyBaseTheme._();

  static ThemeData buildTheme({
    required MoneyBasePalette palette,
    required bool darkMode,
    Color? customPrimary,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      brightness: darkMode ? Brightness.dark : Brightness.light,
      seedColor: customPrimary ?? palette.primary,
      primary: customPrimary ?? palette.primary,
      secondary: palette.secondary,
      background: palette.background,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkMode
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),
    );
  }
}

/// Provides read-write access to the active theme selections.
class ThemeController extends ChangeNotifier {
  ThemeController();

  bool _darkMode = false;
  int _paletteIndex = 0;
  Color? _customPrimary;

  bool get darkMode => _darkMode;
  MoneyBasePalette get palette =>
      kMoneyBasePalettes[_paletteIndex.clamp(0, kMoneyBasePalettes.length - 1)];
  Color? get customPrimary => _customPrimary;

  void setDarkMode(bool value) {
    if (value == _darkMode) return;
    _darkMode = value;
    notifyListeners();
  }

  void selectPalette(int index) {
    if (index == _paletteIndex) return;
    if (index < 0 || index >= kMoneyBasePalettes.length) return;
    _paletteIndex = index;
    notifyListeners();
  }

  void updateCustomPrimary(Color? color) {
    if (color == _customPrimary) return;
    _customPrimary = color;
    notifyListeners();
  }
}

/// Simple [InheritedNotifier] wrapper so screens can read the [ThemeController].
class ThemeControllerProvider extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({
    required super.notifier,
    required super.child,
    super.key,
  });

  static ThemeController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(provider != null, 'ThemeControllerProvider not found in context');
    return provider!.notifier!;
  }
}
