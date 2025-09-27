import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    required this.glassOverlay,
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
  final Color glassOverlay;

  factory MoneyBaseThemeColors.fallback({required bool darkMode}) {
    if (darkMode) {
      return MoneyBaseThemeColors(
        backgroundGradient: const [Colors.black, Colors.black],
        surfaceBackground: const Color(0xFF080808),
        surfaceElevated: const Color(0xFF111111),
        surfaceBorder: Colors.white.withOpacity(0.06),
        surfaceShadow: Colors.black.withOpacity(0.7),
        primaryText: Colors.white,
        mutedText: Colors.white.withOpacity(0.68),
        primaryAccent: MoneyBaseColors.purple,
        secondaryAccent: MoneyBaseColors.blue,
        tertiaryAccent: MoneyBaseColors.orange,
        positive: MoneyBaseColors.green,
        negative: MoneyBaseColors.red,
        warning: MoneyBaseColors.yellow,
        info: MoneyBaseColors.pink,
        glassOverlay: Colors.white.withOpacity(0.04),
      );
    }

    return MoneyBaseThemeColors(
      backgroundGradient: const [Colors.white, Color(0xFFF3F6FF)],
      surfaceBackground: Colors.white,
      surfaceElevated: const Color(0xFFF8F9FE),
      surfaceBorder: MoneyBaseColors.grey.withOpacity(0.1),
      surfaceShadow: Colors.black.withOpacity(0.08),
      primaryText: MoneyBaseColors.grey,
      mutedText: MoneyBaseColors.grey.withOpacity(0.68),
      primaryAccent: MoneyBaseColors.purple,
      secondaryAccent: MoneyBaseColors.blue,
      tertiaryAccent: MoneyBaseColors.orange,
      positive: MoneyBaseColors.green,
      negative: MoneyBaseColors.red,
      warning: MoneyBaseColors.yellow,
      info: MoneyBaseColors.pink,
      glassOverlay: Colors.white.withOpacity(0.65),
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
    Color? glassOverlay,
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
      glassOverlay: glassOverlay ?? this.glassOverlay,
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
      glassOverlay:
          Color.lerp(glassOverlay, other.glassOverlay, t) ?? glassOverlay,
    );
  }
}
