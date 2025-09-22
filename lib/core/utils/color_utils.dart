import 'package:flutter/material.dart';

Color? parseHexColor(String? hex) {
  if (hex == null) {
    return null;
  }

  final value = hex.trim();
  if (value.isEmpty) {
    return null;
  }

  final buffer = StringBuffer();
  if (!value.startsWith('#')) {
    buffer.write('#');
  }
  buffer.write(value.replaceFirst('#', ''));

  final normalized = buffer.toString();
  if (normalized.length == 7) {
    return Color(int.parse(normalized.substring(1), radix: 16) + 0xFF000000);
  }
  if (normalized.length == 9) {
    return Color(int.parse(normalized.substring(1), radix: 16));
  }
  return null;
}
