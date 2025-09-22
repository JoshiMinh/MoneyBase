import 'package:flutter/material.dart';

class IconLibrary {
  const IconLibrary._();

  static const Map<String, IconData> walletIcons = {
    'account_balance_wallet': Icons.account_balance_wallet,
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'savings': Icons.savings,
    'wallet': Icons.wallet,
    'account_balance_wallet_outlined': Icons.account_balance_wallet_outlined,
    'paid': Icons.paid,
    'attach_money': Icons.attach_money,
    'money': Icons.money,
    'currency_exchange': Icons.currency_exchange,
    'travel_explore': Icons.travel_explore,
    'rocket_launch': Icons.rocket_launch,
    'school': Icons.school,
    'luggage': Icons.luggage,
    'store': Icons.store,
    'shopping_bag': Icons.shopping_bag,
    'directions_car': Icons.directions_car,
    'house': Icons.house,
    'phone_iphone': Icons.phone_iphone,
    'devices_other': Icons.devices_other,
  };

  static const Map<String, IconData> categoryIcons = {
    'shopping_bag': Icons.shopping_bag,
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'directions_car': Icons.directions_car,
    'commute': Icons.commute,
    'flight_takeoff': Icons.flight_takeoff,
    'home': Icons.home,
    'fitness_center': Icons.fitness_center,
    'live_tv': Icons.live_tv,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'pets': Icons.pets,
    'child_friendly': Icons.child_friendly,
    'sports_soccer': Icons.sports_soccer,
    'school': Icons.school,
    'work': Icons.work,
    'savings': Icons.savings,
    'volunteer_activism': Icons.volunteer_activism,
    'medical_services': Icons.medical_services,
    'spa': Icons.spa,
    'payments': Icons.payments,
    'local_shipping': Icons.local_shipping,
    'celebration': Icons.celebration,
    'book': Icons.book,
    'computer': Icons.computer,
    'devices_other': Icons.devices_other,
    'travel_explore': Icons.travel_explore,
    'handshake': Icons.handshake,
    'currency_exchange': Icons.currency_exchange,
    'support_agent': Icons.support_agent,
    'emoji_events': Icons.emoji_events,
    'beach_access': Icons.beach_access,
    'biotech': Icons.biotech,
    'cake': Icons.cake,
    'science': Icons.science,
  };

  static IconData iconForWallet(String? name) {
    if (name != null && walletIcons.containsKey(name)) {
      return walletIcons[name]!;
    }
    return Icons.account_balance_wallet_outlined;
  }

  static IconData iconForCategory(String? name) {
    if (name != null && categoryIcons.containsKey(name)) {
      return categoryIcons[name]!;
    }
    return Icons.category_outlined;
  }

  static Iterable<MapEntry<String, IconData>> walletOptions() => walletIcons.entries;

  static Iterable<MapEntry<String, IconData>> categoryOptions() => categoryIcons.entries;
}
