import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palettes.dart';

@immutable
class MoneyBaseThemeColors extends ThemeExtension<MoneyBaseThemeColors> {
  const MoneyBaseThemeColors({
    required this.backgroundGradient,
    required this.surfaceBackground,
  });

  final List<Color> backgroundGradient;
  final Color surfaceBackground;

  @override
  MoneyBaseThemeColors copyWith({
    List<Color>? backgroundGradient,
    Color? surfaceBackground,
  }) {
    return MoneyBaseThemeColors(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      surfaceBackground: surfaceBackground ?? this.surfaceBackground,
    );
  }

  @override
  MoneyBaseThemeColors lerp(
    covariant ThemeExtension<MoneyBaseThemeColors>? other,
    double t,
  ) {
    if (other is! MoneyBaseThemeColors) {
      return this;
    }

    final gradientLength = math.max(backgroundGradient.length, other.backgroundGradient.length);
    final colors = <Color>[];
    for (var i = 0; i < gradientLength; i++) {
      final a = i < backgroundGradient.length
          ? backgroundGradient[i]
          : backgroundGradient.isEmpty
              ? Colors.transparent
              : backgroundGradient.last;
      final b = i < other.backgroundGradient.length
          ? other.backgroundGradient[i]
          : other.backgroundGradient.isEmpty
              ? Colors.transparent
              : other.backgroundGradient.last;
      colors.add(Color.lerp(a, b, t) ?? a);
    }

    return MoneyBaseThemeColors(
      backgroundGradient: colors,
      surfaceBackground: Color.lerp(surfaceBackground, other.surfaceBackground, t) ??
          surfaceBackground,
    );
  }
}

/// Builds themed [ThemeData] instances similar to the Compose `MoneyBaseTheme`.
class MoneyBaseTheme {
  const MoneyBaseTheme._();

  static ThemeData buildTheme({
    required MoneyBasePalette palette,
    required bool darkMode,
    Color? customPrimary,
  }) {
    final seedColor = customPrimary ?? palette.primary;
    final backgroundColor =
        darkMode ? palette.darkBackground : palette.lightBackground;
    final surfaceBlendBase = darkMode ? palette.darkBackground : palette.lightBackground;
    final surfaceOverlay =
        darkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);
    final surfaceColor = Color.alphaBlend(surfaceOverlay, surfaceBlendBase);

    final colorScheme = ColorScheme.fromSeed(
      brightness: darkMode ? Brightness.dark : Brightness.light,
      seedColor: seedColor,
      primary: seedColor,
      secondary: palette.secondary,
      background: backgroundColor,
    ).copyWith(
      surface: surfaceColor,
      surfaceTint: Colors.transparent,
      surfaceContainerHighest: Color.alphaBlend(
        darkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        surfaceColor,
      ),
      surfaceContainerHigh: Color.alphaBlend(
        darkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
        surfaceColor,
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            darkMode ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),
      extensions: [
        MoneyBaseThemeColors(
          backgroundGradient:
              darkMode ? palette.darkGradient : palette.lightGradient,
          surfaceBackground: surfaceColor,
        ),
      ],
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
