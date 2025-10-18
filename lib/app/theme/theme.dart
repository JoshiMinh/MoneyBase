import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'shape_tokens.dart';

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
        backgroundGradient: [
          const Color(0xFF050A14),
          const Color(0xFF0C1524),
          MoneyBaseColors.primary.withOpacity(0.28),
        ],
        surfaceBackground: const Color(0xFF101A2A),
        surfaceElevated: const Color(0xFF182337),
        surfaceBorder: const Color(0x33283A52),
        surfaceShadow: const Color(0x88000000),
        primaryText: Colors.white,
        mutedText: const Color(0xCCF1F5FF),
        primaryAccent: MoneyBaseColors.primary,
        secondaryAccent: MoneyBaseColors.secondary,
        tertiaryAccent: MoneyBaseColors.purple,
        positive: MoneyBaseColors.green,
        negative: MoneyBaseColors.red,
        warning: MoneyBaseColors.yellow,
        info: MoneyBaseColors.blue,
      );
    }

    return MoneyBaseThemeColors(
      backgroundGradient: [
        const Color(0xFFF6F8FC),
        const Color(0xFFEFF4FF),
        MoneyBaseColors.primary.withOpacity(0.18),
      ],
      surfaceBackground: Colors.white,
      surfaceElevated: const Color(0xFFE8F0FF),
      surfaceBorder: const Color(0xFFC8D6EC),
      surfaceShadow: const Color(0x120B1A33),
      primaryText: MoneyBaseColors.grey,
      mutedText: const Color(0x991F2937),
      primaryAccent: MoneyBaseColors.primary,
      secondaryAccent: MoneyBaseColors.secondary,
      tertiaryAccent: MoneyBaseColors.purple,
      positive: MoneyBaseColors.green,
      negative: MoneyBaseColors.red,
      warning: MoneyBaseColors.yellow,
      info: MoneyBaseColors.blue,
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
    final themeColors = _resolveThemeColors(darkMode);
    final backgroundColor = _backgroundColorFor(themeColors);
    final colorScheme = _buildColorScheme(themeColors, darkMode, backgroundColor);

    final baseTheme = ThemeData(
      colorScheme: colorScheme,
      brightness: darkMode ? Brightness.dark : Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: themeColors.surfaceBackground,
      extensions: <ThemeExtension<dynamic>>[themeColors],
    );

    return baseTheme.copyWith(
      appBarTheme: _buildAppBarTheme(themeColors, backgroundColor),
      bottomAppBarTheme: _buildBottomAppBarTheme(themeColors),
      navigationBarTheme:
          _buildNavigationBarTheme(themeColors, backgroundColor, darkMode),
      navigationRailTheme:
          _buildNavigationRailTheme(themeColors, backgroundColor, darkMode),
      floatingActionButtonTheme:
          _buildFloatingActionButtonTheme(themeColors),
      filledButtonTheme: _buildFilledButtonTheme(themeColors),
      textButtonTheme: _buildTextButtonTheme(themeColors),
      outlinedButtonTheme: _buildOutlinedButtonTheme(themeColors),
      inputDecorationTheme: _buildInputDecorationTheme(themeColors, darkMode),
      chipTheme: _buildChipTheme(themeColors, darkMode),
      cardTheme: _buildCardTheme(themeColors),
      dialogTheme: _buildDialogTheme(themeColors),
      dividerTheme: _buildDividerTheme(themeColors),
      listTileTheme: _buildListTileTheme(themeColors),
      bottomSheetTheme: _buildBottomSheetTheme(themeColors),
      snackBarTheme: _buildSnackBarTheme(themeColors),
      progressIndicatorTheme: _buildProgressIndicatorTheme(themeColors),
      extensions: <ThemeExtension<dynamic>>[themeColors],
    );
  }

  static MoneyBaseThemeColors _resolveThemeColors(bool darkMode) {
    final baseColors = MoneyBaseThemeColors.fallback(darkMode: darkMode);
    return baseColors.copyWith(
      surfaceBackground:
          darkMode ? const Color(0xFF0F1827) : Colors.white,
      surfaceElevated:
          darkMode ? const Color(0xFF162235) : const Color(0xFFE3ECFC),
      surfaceBorder:
          darkMode ? const Color(0x3325364B) : const Color(0xFFCAD8ED),
      surfaceShadow:
          darkMode ? const Color(0x77000000) : const Color(0x120B1A33),
    );
  }

  static Color _backgroundColorFor(MoneyBaseThemeColors colors) {
    if (colors.backgroundGradient.isEmpty) {
      return Colors.transparent;
    }
    return colors.backgroundGradient.first;
  }

  static ColorScheme _buildColorScheme(
    MoneyBaseThemeColors themeColors,
    bool darkMode,
    Color backgroundColor,
  ) {
    final base = darkMode ? const ColorScheme.dark() : const ColorScheme.light();
    return base.copyWith(
      primary: themeColors.primaryAccent,
      onPrimary: Colors.white,
      primaryContainer: themeColors.primaryAccent.withOpacity(
        darkMode ? 0.35 : 0.18,
      ),
      onPrimaryContainer:
          darkMode ? Colors.white : themeColors.primaryText,
      secondary: themeColors.secondaryAccent,
      onSecondary: Colors.white,
      secondaryContainer: themeColors.secondaryAccent.withOpacity(
        darkMode ? 0.32 : 0.18,
      ),
      onSecondaryContainer: Colors.white,
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
        darkMode ? 0.5 : 0.26,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(
    MoneyBaseThemeColors themeColors,
    Color backgroundColor,
  ) {
    return AppBarTheme(
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
    );
  }

  static BottomAppBarThemeData _buildBottomAppBarTheme(
    MoneyBaseThemeColors themeColors,
  ) {
    return BottomAppBarThemeData(
      color: themeColors.surfaceBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme(
    MoneyBaseThemeColors themeColors,
    Color backgroundColor,
    bool darkMode,
  ) {
    return NavigationBarThemeData(
      backgroundColor: _blend(
        backgroundColor,
        themeColors.surfaceBackground,
        darkMode ? 0.45 : 0.12,
      ),
      indicatorColor: themeColors.secondaryAccent.withOpacity(
        darkMode ? 0.26 : 0.18,
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
    );
  }

  static NavigationRailThemeData _buildNavigationRailTheme(
    MoneyBaseThemeColors themeColors,
    Color backgroundColor,
    bool darkMode,
  ) {
    return NavigationRailThemeData(
      backgroundColor: _blend(
        backgroundColor,
        themeColors.surfaceBackground,
        darkMode ? 0.45 : 0.12,
      ),
      indicatorColor: themeColors.secondaryAccent.withOpacity(
        darkMode ? 0.26 : 0.18,
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
    );
  }

  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme(
    MoneyBaseThemeColors themeColors,
  ) {
    return FloatingActionButtonThemeData(
      backgroundColor: themeColors.secondaryAccent,
      foregroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: MoneyBaseShapeTokens.borderRadiusLarge,
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(
    MoneyBaseThemeColors themeColors,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: themeColors.primaryAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const RoundedRectangleBorder(
          borderRadius: MoneyBaseShapeTokens.borderRadiusMedium,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(
    MoneyBaseThemeColors themeColors,
  ) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: themeColors.primaryAccent,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    MoneyBaseThemeColors themeColors,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: themeColors.primaryAccent,
        side: BorderSide(color: themeColors.primaryAccent.withOpacity(0.5)),
        shape: const RoundedRectangleBorder(
          borderRadius: MoneyBaseShapeTokens.borderRadiusMedium,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
    MoneyBaseThemeColors themeColors,
    bool darkMode,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: darkMode
          ? _blend(themeColors.surfaceBackground, Colors.black, 0.35)
          : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: MoneyBaseShapeTokens.borderRadiusLarge,
        borderSide: BorderSide(color: themeColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: MoneyBaseShapeTokens.borderRadiusLarge,
        borderSide: BorderSide(color: themeColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: MoneyBaseShapeTokens.borderRadiusLarge,
        borderSide: BorderSide(color: themeColors.primaryAccent),
      ),
      hintStyle: TextStyle(color: themeColors.mutedText),
      labelStyle: TextStyle(color: themeColors.mutedText),
    );
  }

  static ChipThemeData _buildChipTheme(
    MoneyBaseThemeColors themeColors,
    bool darkMode,
  ) {
    return ChipThemeData(
      backgroundColor: themeColors.secondaryAccent.withOpacity(
        darkMode ? 0.22 : 0.14,
      ),
      selectedColor: themeColors.primaryAccent.withOpacity(
        darkMode ? 0.30 : 0.22,
      ),
      disabledColor: themeColors.surfaceBorder.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(color: themeColors.primaryText),
      secondaryLabelStyle: TextStyle(color: themeColors.primaryText),
      shape: const RoundedRectangleBorder(
        borderRadius: MoneyBaseShapeTokens.borderRadiusMedium,
      ),
      brightness: darkMode ? Brightness.dark : Brightness.light,
    );
  }

  static CardThemeData _buildCardTheme(MoneyBaseThemeColors themeColors) {
    return CardThemeData(
      color: themeColors.surfaceBackground,
      shadowColor: themeColors.surfaceShadow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: MoneyBaseShapeTokens.borderRadiusLarge,
        side: BorderSide(color: themeColors.surfaceBorder),
      ),
    );
  }

  static DialogThemeData _buildDialogTheme(MoneyBaseThemeColors themeColors) {
    return DialogThemeData(
      backgroundColor: themeColors.surfaceBackground,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: MoneyBaseShapeTokens.borderRadiusLarge,
      ),
    );
  }

  static DividerThemeData _buildDividerTheme(
    MoneyBaseThemeColors themeColors,
  ) {
    return DividerThemeData(
      color: themeColors.surfaceBorder,
      thickness: 1,
      space: 32,
    );
  }

  static ListTileThemeData _buildListTileTheme(
    MoneyBaseThemeColors themeColors,
  ) {
    return ListTileThemeData(
      iconColor: themeColors.primaryAccent,
      textColor: themeColors.primaryText,
      tileColor: themeColors.surfaceBackground,
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme(
    MoneyBaseThemeColors themeColors,
  ) {
    return BottomSheetThemeData(
      backgroundColor: themeColors.surfaceBackground,
      modalBackgroundColor: themeColors.surfaceBackground,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MoneyBaseShapeTokens.cornerExtraLarge),
        ),
      ),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(
    MoneyBaseThemeColors themeColors,
  ) {
    return SnackBarThemeData(
      backgroundColor: themeColors.tertiaryAccent,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: MoneyBaseShapeTokens.borderRadiusMedium,
      ),
    );
  }

  static ProgressIndicatorThemeData _buildProgressIndicatorTheme(
    MoneyBaseThemeColors themeColors,
  ) {
    return ProgressIndicatorThemeData(
      color: themeColors.secondaryAccent,
      linearTrackColor: themeColors.surfaceBorder,
      circularTrackColor: themeColors.surfaceBorder,
    );
  }

  static Color _blend(Color a, Color b, double t) {
    return Color.lerp(a, b, t) ?? a;
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
