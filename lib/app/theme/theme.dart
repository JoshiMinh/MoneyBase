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
    required this.surfaceElevated,
    required this.surfaceBorder,
    required this.surfaceShadow,
    required this.primaryText,
    required this.mutedText,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.tertiaryAccent,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.info,
  });

  final List<Color> backgroundGradient;
  final Color surfaceBackground;
  final Color surfaceElevated;
  final Color surfaceBorder;
  final Color surfaceShadow;
  final Color primaryText;
  final Color mutedText;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color tertiaryAccent;
  final Color positive;
  final Color negative;
  final Color warning;
  final Color info;

  factory MoneyBaseThemeColors.fallback({required bool darkMode}) {
    if (darkMode) {
      return const MoneyBaseThemeColors(
        backgroundGradient: [Color(0xFF141822), Color(0xFF0C0F16)],
        surfaceBackground: Color(0xFF181B25),
        surfaceElevated: Color(0xFF202433),
        surfaceBorder: Color(0x33FFFFFF),
        surfaceShadow: Color(0x99000000),
        primaryText: Colors.white,
        mutedText: Color(0xCCFFFFFF),
        primaryAccent: Color(0xFF7E9CFF),
        secondaryAccent: Color(0xFF5EEAD4),
        tertiaryAccent: Color(0xFFFFB74D),
        positive: Color(0xFF66BB6A),
        negative: Color(0xFFFF8A80),
        warning: Color(0xFFFFCA28),
        info: Color(0xFF64B5F6),
      );
    }

    return const MoneyBaseThemeColors(
      backgroundGradient: [Color(0xFFF8FAFF), Color(0xFFF1F4FF)],
      surfaceBackground: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFF5F7FF),
      surfaceBorder: Color(0x190C1A4B),
      surfaceShadow: Color(0x1A000000),
      primaryText: Color(0xFF20242F),
      mutedText: Color(0xB320242F),
      primaryAccent: Color(0xFF3D5AFE),
      secondaryAccent: Color(0xFF00B0FF),
      tertiaryAccent: Color(0xFF8E24AA),
      positive: Color(0xFF2E7D32),
      negative: Color(0xFFC62828),
      warning: Color(0xFFF57F17),
      info: Color(0xFF1565C0),
    );
  }

  @override
  MoneyBaseThemeColors copyWith({
    List<Color>? backgroundGradient,
    Color? surfaceBackground,
    Color? surfaceElevated,
    Color? surfaceBorder,
    Color? surfaceShadow,
    Color? primaryText,
    Color? mutedText,
    Color? primaryAccent,
    Color? secondaryAccent,
    Color? tertiaryAccent,
    Color? positive,
    Color? negative,
    Color? warning,
    Color? info,
  }) {
    return MoneyBaseThemeColors(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      surfaceBackground: surfaceBackground ?? this.surfaceBackground,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      surfaceShadow: surfaceShadow ?? this.surfaceShadow,
      primaryText: primaryText ?? this.primaryText,
      mutedText: mutedText ?? this.mutedText,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      tertiaryAccent: tertiaryAccent ?? this.tertiaryAccent,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
      info: info ?? this.info,
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
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t) ?? surfaceElevated,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t) ?? surfaceBorder,
      surfaceShadow: Color.lerp(surfaceShadow, other.surfaceShadow, t) ?? surfaceShadow,
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      mutedText: Color.lerp(mutedText, other.mutedText, t) ?? mutedText,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t) ?? primaryAccent,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t) ?? secondaryAccent,
      tertiaryAccent: Color.lerp(tertiaryAccent, other.tertiaryAccent, t) ?? tertiaryAccent,
      positive: Color.lerp(positive, other.positive, t) ?? positive,
      negative: Color.lerp(negative, other.negative, t) ?? negative,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
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
    final gradient = darkMode ? palette.darkGradient : palette.lightGradient;
    final backgroundColor = darkMode ? palette.darkBackground : palette.lightBackground;
    final baseColors = MoneyBaseThemeColors.fallback(darkMode: darkMode);
    final themeColors = baseColors.copyWith(
      backgroundGradient: gradient,
      surfaceBackground: darkMode ? const Color(0xFF1C1F2B) : Colors.white,
      surfaceElevated: darkMode ? const Color(0xFF262A3A) : const Color(0xFFF5F7FF),
      surfaceBorder: darkMode ? const Color(0x40FFFFFF) : const Color(0x1A0F1A3F),
      surfaceShadow: darkMode ? const Color(0x88000000) : const Color(0x14000000),
      primaryAccent: customPrimary ?? palette.primary,
      secondaryAccent: palette.secondary,
      tertiaryAccent: darkMode
          ? palette.secondary.withOpacity(0.85)
          : (customPrimary ?? palette.primary).withOpacity(0.7),
    );

    final colorScheme = (darkMode ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      primary: themeColors.primaryAccent,
      onPrimary: Colors.white,
      secondary: themeColors.secondaryAccent,
      onSecondary: darkMode ? Colors.black : Colors.white,
      tertiary: themeColors.tertiaryAccent,
      background: backgroundColor,
      surface: themeColors.surfaceBackground,
      surfaceTint: Colors.transparent,
      onSurface: themeColors.primaryText,
      onBackground: themeColors.primaryText,
      error: themeColors.negative,
      onError: Colors.white,
      outline: themeColors.surfaceBorder,
      outlineVariant: themeColors.surfaceBorder,
      surfaceContainerHigh: themeColors.surfaceElevated,
      surfaceContainerHighest: themeColors.surfaceElevated,
      secondaryContainer: themeColors.secondaryAccent.withOpacity(darkMode ? 0.28 : 0.18),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: themeColors.surfaceBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: themeColors.primaryText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkMode ? const Color(0xFF161926) : const Color(0xFFF1F4FF),
        indicatorColor: themeColors.secondaryAccent.withOpacity(darkMode ? 0.26 : 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final active = states.contains(MaterialState.selected);
          final baseColor = themeColors.mutedText;
          return IconThemeData(
            color: active ? themeColors.primaryAccent : baseColor,
          );
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final active = states.contains(MaterialState.selected);
          final baseColor = themeColors.mutedText;
          return TextStyle(
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? themeColors.primaryAccent : baseColor,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: darkMode ? const Color(0xFF161926) : const Color(0xFFF1F4FF),
        indicatorColor: themeColors.secondaryAccent.withOpacity(darkMode ? 0.26 : 0.18),
        selectedLabelTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: themeColors.primaryAccent,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: themeColors.mutedText,
        ),
        unselectedIconTheme: IconThemeData(
          color: themeColors.mutedText,
        ),
        selectedIconTheme: IconThemeData(color: themeColors.primaryAccent),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: themeColors.secondaryAccent,
        foregroundColor: darkMode ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      extensions: [
        themeColors,
      ],
    );
  }
}

extension MoneyBaseThemeColorsContext on BuildContext {
  MoneyBaseThemeColors get moneyBaseColors {
    final theme = Theme.of(this);
    return theme.extension<MoneyBaseThemeColors>() ??
        MoneyBaseThemeColors.fallback(darkMode: theme.brightness == Brightness.dark);
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
