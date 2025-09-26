import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

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
      return MoneyBaseThemeColors(
        backgroundGradient: const [MoneyBaseColors.grey, MoneyBaseColors.grey],
        surfaceBackground: MoneyBaseColors.grey.withOpacity(0.96),
        surfaceElevated: MoneyBaseColors.grey.withOpacity(0.84),
        surfaceBorder: MoneyBaseColors.grey.withOpacity(0.32),
        surfaceShadow: MoneyBaseColors.grey.withOpacity(0.6),
        primaryText: Colors.white,
        mutedText: Colors.white.withOpacity(0.68),
        primaryAccent: MoneyBaseColors.purple,
        secondaryAccent: MoneyBaseColors.blue,
        tertiaryAccent: MoneyBaseColors.orange,
        positive: MoneyBaseColors.green,
        negative: MoneyBaseColors.red,
        warning: MoneyBaseColors.yellow,
        info: MoneyBaseColors.pink,
      );
    }

    return MoneyBaseThemeColors(
      backgroundGradient: const [Colors.white, Colors.white],
      surfaceBackground: Colors.white,
      surfaceElevated: Colors.white.withOpacity(0.92),
      surfaceBorder: MoneyBaseColors.grey.withOpacity(0.18),
      surfaceShadow: MoneyBaseColors.grey.withOpacity(0.12),
      primaryText: MoneyBaseColors.grey,
      mutedText: MoneyBaseColors.grey.withOpacity(0.68),
      primaryAccent: MoneyBaseColors.purple,
      secondaryAccent: MoneyBaseColors.blue,
      tertiaryAccent: MoneyBaseColors.orange,
      positive: MoneyBaseColors.green,
      negative: MoneyBaseColors.red,
      warning: MoneyBaseColors.yellow,
      info: MoneyBaseColors.pink,
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

    final gradientLength = math.max(
      backgroundGradient.length,
      other.backgroundGradient.length,
    );
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
      surfaceBackground:
          Color.lerp(surfaceBackground, other.surfaceBackground, t) ??
          surfaceBackground,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t) ??
          surfaceElevated,
      surfaceBorder:
          Color.lerp(surfaceBorder, other.surfaceBorder, t) ?? surfaceBorder,
      surfaceShadow:
          Color.lerp(surfaceShadow, other.surfaceShadow, t) ?? surfaceShadow,
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      mutedText: Color.lerp(mutedText, other.mutedText, t) ?? mutedText,
      primaryAccent:
          Color.lerp(primaryAccent, other.primaryAccent, t) ?? primaryAccent,
      secondaryAccent:
          Color.lerp(secondaryAccent, other.secondaryAccent, t) ??
          secondaryAccent,
      tertiaryAccent:
          Color.lerp(tertiaryAccent, other.tertiaryAccent, t) ?? tertiaryAccent,
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

  static ThemeData buildTheme({required bool darkMode}) {
    final baseColors = MoneyBaseThemeColors.fallback(darkMode: darkMode);
    final backgroundColor = baseColors.backgroundGradient.first;
    final themeColors = baseColors.copyWith(
      surfaceBackground:
          darkMode ? MoneyBaseColors.grey.withOpacity(0.96) : Colors.white,
      surfaceElevated:
          darkMode ? MoneyBaseColors.grey.withOpacity(0.88) : Colors.white,
      surfaceBorder:
          darkMode ? MoneyBaseColors.grey.withOpacity(0.32) : baseColors.surfaceBorder,
      surfaceShadow:
          darkMode ? MoneyBaseColors.grey.withOpacity(0.6) : baseColors.surfaceShadow,
    );

    final colorScheme =
        (darkMode ? const ColorScheme.dark() : const ColorScheme.light())
            .copyWith(
              primary: themeColors.primaryAccent,
              onPrimary: Colors.white,
              primaryContainer: darkMode
                  ? MoneyBaseColors.purple.withOpacity(0.38)
                  : MoneyBaseColors.purple.withOpacity(0.18),
              onPrimaryContainer: darkMode
                  ? Colors.white
                  : themeColors.primaryText,
              secondary: themeColors.secondaryAccent,
              onSecondary: darkMode ? Colors.black : Colors.white,
              secondaryContainer: themeColors.secondaryAccent.withOpacity(
                darkMode ? 0.32 : 0.18,
              ),
              onSecondaryContainer: darkMode
                  ? Colors.black
                  : themeColors.primaryText,
              tertiary: themeColors.tertiaryAccent,
              onTertiary: Colors.white,
              background: backgroundColor,
              onBackground: themeColors.primaryText,
              surface: themeColors.surfaceBackground,
              surfaceTint: Colors.transparent,
              onSurface: themeColors.primaryText,
              onSurfaceVariant: themeColors.mutedText,
              error: themeColors.negative,
              onError: Colors.white,
              outline: themeColors.surfaceBorder,
              outlineVariant: themeColors.surfaceBorder,
              surfaceContainerHigh: themeColors.surfaceElevated,
              surfaceContainerHighest: themeColors.surfaceElevated,
              shadow: themeColors.surfaceShadow,
              scrim: Colors.black.withOpacity(darkMode ? 0.6 : 0.3),
              inversePrimary: themeColors.primaryAccent.withOpacity(
                darkMode ? 0.6 : 0.32,
              ),
            );

    return ThemeData(
      colorScheme: colorScheme,
      brightness: darkMode ? Brightness.dark : Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: themeColors.surfaceBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: themeColors.primaryText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: themeColors.primaryText),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: themeColors.primaryText,
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: themeColors.surfaceBackground,
        surfaceTintColor:
            Colors.transparent, // optional, to match your M3 usage
        elevation: 0, // optional, mirrors your flat surfaces
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color.lerp(
          backgroundColor,
          themeColors.surfaceBackground,
          darkMode ? 0.45 : 0.12,
        ),
        indicatorColor: themeColors.primaryAccent.withOpacity(
          darkMode ? 0.24 : 0.18,
        ),
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
        backgroundColor: Color.lerp(
          backgroundColor,
          themeColors.surfaceBackground,
          darkMode ? 0.45 : 0.12,
        ),
        indicatorColor: themeColors.primaryAccent.withOpacity(
          darkMode ? 0.24 : 0.18,
        ),
        selectedLabelTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: themeColors.primaryAccent,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: themeColors.mutedText,
        ),
        unselectedIconTheme: IconThemeData(color: themeColors.mutedText),
        selectedIconTheme: IconThemeData(color: themeColors.primaryAccent),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: themeColors.secondaryAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: themeColors.primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: themeColors.primaryAccent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: themeColors.primaryAccent,
          side: BorderSide(color: themeColors.primaryAccent.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkMode
            ? Color.lerp(themeColors.surfaceBackground, Colors.black, 0.35) ??
                themeColors.surfaceBackground
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: themeColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: themeColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: themeColors.primaryAccent),
        ),
        hintStyle: TextStyle(color: themeColors.mutedText),
        labelStyle: TextStyle(color: themeColors.mutedText),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: themeColors.secondaryAccent.withOpacity(
          darkMode ? 0.16 : 0.12,
        ),
        selectedColor: themeColors.secondaryAccent.withOpacity(
          darkMode ? 0.26 : 0.2,
        ),
        disabledColor: themeColors.surfaceBorder.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(color: themeColors.primaryText),
        secondaryLabelStyle: TextStyle(color: themeColors.primaryText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        brightness: darkMode ? Brightness.dark : Brightness.light,
      ),
      cardTheme: CardThemeData(
        color: themeColors.surfaceBackground,
        shadowColor: themeColors.surfaceShadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: themeColors.surfaceBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: themeColors.surfaceBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      dividerTheme: DividerThemeData(
        color: themeColors.surfaceBorder,
        thickness: 1,
        space: 32,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: themeColors.primaryAccent,
        textColor: themeColors.primaryText,
        tileColor: themeColors.surfaceBackground,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: themeColors.surfaceBackground,
        modalBackgroundColor: themeColors.surfaceBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: themeColors.primaryAccent,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: themeColors.primaryAccent,
        linearTrackColor: themeColors.surfaceBorder,
        circularTrackColor: themeColors.surfaceBorder,
      ),
      extensions: [themeColors],
    );
  }
}

extension MoneyBaseThemeColorsContext on BuildContext {
  MoneyBaseThemeColors get moneyBaseColors {
    final theme = Theme.of(this);
    return theme.extension<MoneyBaseThemeColors>() ??
        MoneyBaseThemeColors.fallback(
          darkMode: theme.brightness == Brightness.dark,
        );
  }
}

/// Provides read-write access to the active theme selections.
class ThemeController extends ChangeNotifier {
  ThemeController();

  bool _darkMode = false;
  SharedPreferences? _prefs;

  static const _darkModeKey = 'theme.darkMode';

  bool get darkMode => _darkMode;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> loadFromStorage() async {
    final prefs = await _ensurePrefs();
    _darkMode = prefs.getBool(_darkModeKey) ?? _darkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (value == _darkMode) return;
    _darkMode = value;
    notifyListeners();
    unawaited(_saveDarkMode());
  }

  Future<void> _saveDarkMode() async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_darkModeKey, _darkMode);
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
