import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final backgroundColor = darkMode ? Colors.black : Colors.white;
    final surfaceBase = darkMode ? const Color(0xFF101010) : const Color(0xFFF5F5F5);
    final highSurface = darkMode ? const Color(0xFF161616) : const Color(0xFFFFFFFF);
    final outlineColor =
        darkMode ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0);

    final colorScheme = ColorScheme.fromSeed(
      brightness: darkMode ? Brightness.dark : Brightness.light,
      seedColor: seedColor,
      primary: seedColor,
      secondary: palette.secondary,
      background: backgroundColor,
    ).copyWith(
      surface: surfaceBase,
      surfaceTint: Colors.transparent,
      onBackground: darkMode ? Colors.white : Colors.black,
      onSurface: darkMode ? Colors.white : Colors.black,
      surfaceContainerHigh: highSurface,
      surfaceContainerHighest: highSurface,
      outline: outlineColor,
      outlineVariant: outlineColor,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: highSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkMode ? Colors.black : Colors.white,
        foregroundColor: darkMode ? Colors.white : Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF9F9F9),
        indicatorColor: colorScheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final active = states.contains(MaterialState.selected);
          final baseColor = darkMode ? Colors.white : Colors.black;
          return IconThemeData(
            color: active ? colorScheme.primary : baseColor.withOpacity(0.68),
          );
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final active = states.contains(MaterialState.selected);
          final baseColor = darkMode ? Colors.white : Colors.black;
          return TextStyle(
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? colorScheme.primary : baseColor.withOpacity(0.68),
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: darkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF9F9F9),
        indicatorColor: colorScheme.secondaryContainer,
        selectedLabelTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: (darkMode ? Colors.white : Colors.black).withOpacity(0.68),
        ),
        unselectedIconTheme: IconThemeData(
          color: (darkMode ? Colors.white : Colors.black).withOpacity(0.68),
        ),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      extensions: [
        MoneyBaseThemeColors(
          backgroundGradient: [
            if (darkMode)
              Colors.black
            else
              Colors.white,
            if (darkMode)
              Colors.black
            else
              Colors.white,
          ],
          surfaceBackground: highSurface,
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
  SharedPreferences? _prefs;

  static const _darkModeKey = 'theme.darkMode';
  static const _paletteKey = 'theme.palette';
  static const _customPrimaryKey = 'theme.customPrimary';

  bool get darkMode => _darkMode;
  MoneyBasePalette get palette =>
      kMoneyBasePalettes[_paletteIndex.clamp(0, kMoneyBasePalettes.length - 1)];
  Color? get customPrimary => _customPrimary;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> loadFromStorage() async {
    final prefs = await _ensurePrefs();
    _darkMode = prefs.getBool(_darkModeKey) ?? _darkMode;
    _paletteIndex = prefs.getInt(_paletteKey) ?? _paletteIndex;
    final customColorValue = prefs.getInt(_customPrimaryKey);
    _customPrimary = customColorValue != null ? Color(customColorValue) : null;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (value == _darkMode) return;
    _darkMode = value;
    notifyListeners();
    unawaited(_saveDarkMode());
  }

  void selectPalette(int index) {
    if (index == _paletteIndex) return;
    if (index < 0 || index >= kMoneyBasePalettes.length) return;
    _paletteIndex = index;
    notifyListeners();
    unawaited(_savePalette());
  }

  void updateCustomPrimary(Color? color) {
    if (color == _customPrimary) return;
    _customPrimary = color;
    notifyListeners();
    unawaited(_saveCustomPrimary());
  }

  Future<void> _saveDarkMode() async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_darkModeKey, _darkMode);
  }

  Future<void> _savePalette() async {
    final prefs = await _ensurePrefs();
    await prefs.setInt(_paletteKey, _paletteIndex);
  }

  Future<void> _saveCustomPrimary() async {
    final prefs = await _ensurePrefs();
    if (_customPrimary == null) {
      await prefs.remove(_customPrimaryKey);
    } else {
      await prefs.setInt(_customPrimaryKey, _customPrimary!.value);
    }
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
