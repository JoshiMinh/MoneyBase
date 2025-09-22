import 'package:flutter/material.dart';

/// Represents a selectable color palette for the application theme.
class MoneyBasePalette {
  const MoneyBasePalette({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.lightBackground,
    required this.darkBackground,
    required this.lightGradient,
    required this.darkGradient,
  });

  final String name;
  final Color primary;
  final Color secondary;
  final Color lightBackground;
  final Color darkBackground;
  final List<Color> lightGradient;
  final List<Color> darkGradient;
}

/// Predefined palettes inspired by vibrant material tones.
const List<MoneyBasePalette> kMoneyBasePalettes = [
  MoneyBasePalette(
    name: 'Radiant Red',
    primary: Color(0xFFD32F2F),
    secondary: Color(0xFFFFB74D),
    lightBackground: Color(0xFFFFEBEE),
    darkBackground: Color(0xFF2B0A0E),
    lightGradient: [Color(0xFFFFCDD2), Color(0xFFFFEBEE)],
    darkGradient: [Color(0xFF4A0D18), Color(0xFF1C0306)],
  ),
  MoneyBasePalette(
    name: 'Bold Blue',
    primary: Color(0xFF1565C0),
    secondary: Color(0xFF64B5F6),
    lightBackground: Color(0xFFE3F2FD),
    darkBackground: Color(0xFF081B33),
    lightGradient: [Color(0xFF90CAF9), Color(0xFFE3F2FD)],
    darkGradient: [Color(0xFF0E2A4C), Color(0xFF040B16)],
  ),
  MoneyBasePalette(
    name: 'Garden Green',
    primary: Color(0xFF2E7D32),
    secondary: Color(0xFF81C784),
    lightBackground: Color(0xFFE8F5E9),
    darkBackground: Color(0xFF0C1F11),
    lightGradient: [Color(0xFFA5D6A7), Color(0xFFE8F5E9)],
    darkGradient: [Color(0xFF123821), Color(0xFF050F08)],
  ),
  MoneyBasePalette(
    name: 'Sunbeam Yellow',
    primary: Color(0xFFF9A825),
    secondary: Color(0xFFFFE082),
    lightBackground: Color(0xFFFFF8E1),
    darkBackground: Color(0xFF251800),
    lightGradient: [Color(0xFFFFE082), Color(0xFFFFF8E1)],
    darkGradient: [Color(0xFF3E2A02), Color(0xFF120900)],
  ),
  MoneyBasePalette(
    name: 'Royal Purple',
    primary: Color(0xFF6A1B9A),
    secondary: Color(0xFFBA68C8),
    lightBackground: Color(0xFFF3E5F5),
    darkBackground: Color(0xFF15091F),
    lightGradient: [Color(0xFFCE93D8), Color(0xFFF3E5F5)],
    darkGradient: [Color(0xFF2B1440), Color(0xFF0A0412)],
  ),
  MoneyBasePalette(
    name: 'Playful Pink',
    primary: Color(0xFFC2185B),
    secondary: Color(0xFFF48FB1),
    lightBackground: Color(0xFFFCE4EC),
    darkBackground: Color(0xFF300514),
    lightGradient: [Color(0xFFF8BBD0), Color(0xFFFCE4EC)],
    darkGradient: [Color(0xFF4F1026), Color(0xFF140208)],
  ),
  MoneyBasePalette(
    name: 'Urban Gray',
    primary: Color(0xFF546E7A),
    secondary: Color(0xFF90A4AE),
    lightBackground: Color(0xFFECEFF1),
    darkBackground: Color(0xFF11181E),
    lightGradient: [Color(0xFFCFD8DC), Color(0xFFECEFF1)],
    darkGradient: [Color(0xFF1E2A30), Color(0xFF070B0E)],
  ),
];
