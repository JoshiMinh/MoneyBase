import 'package:flutter/material.dart';

/// Represents a selectable color palette for the application theme.
class MoneyBasePalette {
  const MoneyBasePalette({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
  });

  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
}

/// Predefined palettes inspired by the legacy Jetpack Compose theme options.
const List<MoneyBasePalette> kMoneyBasePalettes = [
  MoneyBasePalette(
    name: 'Classic Blue',
    primary: Color(0xFF1565C0),
    secondary: Color(0xFFFFCA28),
    background: Color(0xFFF5F5F5),
  ),
  MoneyBasePalette(
    name: 'Emerald',
    primary: Color(0xFF2E7D32),
    secondary: Color(0xFF80CBC4),
    background: Color(0xFFF1F8E9),
  ),
  MoneyBasePalette(
    name: 'Sunset',
    primary: Color(0xFFF4511E),
    secondary: Color(0xFFFF8A65),
    background: Color(0xFFFFF3E0),
  ),
];
