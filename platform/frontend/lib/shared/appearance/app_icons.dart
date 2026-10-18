import 'package:material_ui/material_ui.dart';

/// Icon names the API accepts (backend `Shared/Constants/IconCatalog`, also
/// served by `GET /icons`), resolved statically so icon tree-shaking keeps
/// working. Keep in sync with the backend catalog.
abstract final class AppIcons {
  static const fallback = Icons.label_outline;

  /// Grouped like the backend catalog; the picker shows them in this order.
  static const groups = <String, Map<String, IconData>>{
    'finance': {
      'savings': Icons.savings,
      'account_balance': Icons.account_balance,
      'account_balance_wallet': Icons.account_balance_wallet,
      'credit_card': Icons.credit_card,
      'paid': Icons.paid,
      'attach_money': Icons.attach_money,
      'trending_up': Icons.trending_up,
      'receipt_long': Icons.receipt_long,
    },
    'home': {
      'home': Icons.home,
      'house': Icons.house,
      'chair': Icons.chair,
      'kitchen': Icons.kitchen,
      'bed': Icons.bed,
      'lightbulb': Icons.lightbulb,
      'build': Icons.build,
      'yard': Icons.yard,
    },
    'transport': {
      'directions_car': Icons.directions_car,
      'two_wheeler': Icons.two_wheeler,
      'directions_bus': Icons.directions_bus,
      'train': Icons.train,
      'local_gas_station': Icons.local_gas_station,
      'electric_car': Icons.electric_car,
      'pedal_bike': Icons.pedal_bike,
      'local_taxi': Icons.local_taxi,
    },
    'travel': {
      'flight': Icons.flight,
      'flight_takeoff': Icons.flight_takeoff,
      'luggage': Icons.luggage,
      'beach_access': Icons.beach_access,
      'hotel': Icons.hotel,
      'map': Icons.map,
      'explore': Icons.explore,
      'sailing': Icons.sailing,
    },
    'health': {
      'favorite': Icons.favorite,
      'fitness_center': Icons.fitness_center,
      'local_hospital': Icons.local_hospital,
      'medical_services': Icons.medical_services,
      'spa': Icons.spa,
      'self_improvement': Icons.self_improvement,
      'medication': Icons.medication,
      'monitor_heart': Icons.monitor_heart,
    },
    'education': {
      'school': Icons.school,
      'menu_book': Icons.menu_book,
      'science': Icons.science,
      'calculate': Icons.calculate,
      'laptop_chromebook': Icons.laptop_chromebook,
      'language': Icons.language,
      'psychology': Icons.psychology,
      'history_edu': Icons.history_edu,
    },
    'leisure': {
      'sports_esports': Icons.sports_esports,
      'movie': Icons.movie,
      'music_note': Icons.music_note,
      'theaters': Icons.theaters,
      'sports_soccer': Icons.sports_soccer,
      'celebration': Icons.celebration,
      'camera_alt': Icons.camera_alt,
      'restaurant': Icons.restaurant,
    },
    'shopping': {
      'shopping_cart': Icons.shopping_cart,
      'shopping_bag': Icons.shopping_bag,
      'storefront': Icons.storefront,
      'local_mall': Icons.local_mall,
      'checkroom': Icons.checkroom,
      'redeem': Icons.redeem,
      'local_offer': Icons.local_offer,
      'diamond': Icons.diamond,
    },
    'tech': {
      'smartphone': Icons.smartphone,
      'laptop': Icons.laptop,
      'headphones': Icons.headphones,
      'watch': Icons.watch,
      'tv': Icons.tv,
      'computer': Icons.computer,
      'videogame_asset': Icons.videogame_asset,
      'memory': Icons.memory,
    },
    'family': {
      'family_restroom': Icons.family_restroom,
      'child_care': Icons.child_care,
      'pets': Icons.pets,
      'cake': Icons.cake,
      'volunteer_activism': Icons.volunteer_activism,
      'escalator_warning': Icons.escalator_warning,
      'stroller': Icons.stroller,
      'elderly': Icons.elderly,
    },
  };

  static final Map<String, IconData> _byName = {
    for (final group in groups.values) ...group,
  };

  /// Unknown names (catalog drift) fall back to a neutral icon.
  static IconData resolve(String? name) => _byName[name] ?? fallback;
}
