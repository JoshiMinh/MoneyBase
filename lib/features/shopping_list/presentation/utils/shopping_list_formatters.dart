import 'package:moneybase/core/models/shopping_item.dart';
import 'package:moneybase/core/models/shopping_list.dart';

String formatShoppingDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[date.month - 1];
  final day = date.day.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$month $day, $year';
}

extension ShoppingListTypeX on ShoppingListType {
  String get label {
    switch (this) {
      case ShoppingListType.grocery:
        return 'Grocery';
      case ShoppingListType.shopping:
        return 'Shopping';
    }
  }
}

extension ShoppingItemPriorityX on ShoppingItemPriority {
  String get label => name.toLowerCase();

  String get labelTitleCase =>
      '${name[0].toUpperCase()}${name.substring(1).toLowerCase()}';
}
