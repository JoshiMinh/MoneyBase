import 'package:flutter/material.dart';

/// Shared shape tokens used to keep rounded corners consistent across MoneyBase.
@immutable
class MoneyBaseShapeTokens {
  const MoneyBaseShapeTokens._();

  static const double cornerSmall = 4;
  static const double cornerMedium = 6;
  static const double cornerLarge = 8;
  static const double cornerExtraLarge = 10;

  static const BorderRadius borderRadiusSmall =
      BorderRadius.all(Radius.circular(cornerSmall));
  static const BorderRadius borderRadiusMedium =
      BorderRadius.all(Radius.circular(cornerMedium));
  static const BorderRadius borderRadiusLarge =
      BorderRadius.all(Radius.circular(cornerLarge));
  static const BorderRadius borderRadiusExtraLarge =
      BorderRadius.all(Radius.circular(cornerExtraLarge));
}
