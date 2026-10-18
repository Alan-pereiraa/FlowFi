import 'package:material_ui/material_ui.dart';

/// One group of the backend's icon catalog (`GET /icons`).
class IconGroup {
  const IconGroup({required this.id, required this.label, required this.names});

  final String id;

  /// pt-BR heading shown in the picker.
  final String label;
  final List<String> names;
}

/// Icon names the API accepts (backend `Shared/Constants/IconCatalog`, also
/// served by `GET /icons`), resolved statically so icon tree-shaking keeps
/// working. Keep in sync with the backend catalog.
///
/// The API stores icons by their Flutter `Icons` *name* (`"flight"`). This is
/// the client side of that contract: name -> [IconData], plus the pt-BR
/// grouping used by the picker.
///
/// The catalog is a closed set validated by the backend (`IconCatalog`), so it
/// is bundled instead of fetched; when the backend adds an icon, add it here.
/// An unknown name renders [fallback] instead of failing.
abstract final class AppIcons {
  static const legacyFallback = Icons.label_outline;
  static const fallback = Icons.category_outlined;

  /// Used when the user saves without choosing an icon.
  static const defaultCategory = 'local_offer';
  static const defaultGoal = 'savings';

  /// Grouped like the backend catalog; the picker shows them in this order.
  static const groupsByKey = <String, Map<String, IconData>>{
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

  static final Map<String, IconData> _byNameFromGroups = {
    for (final group in groupsByKey.values) ...group,
  };

  /// Unknown names (catalog drift) fall back to a neutral icon.
  static IconData resolveFromGroups(String? name) =>
      _byNameFromGroups[name] ?? legacyFallback;

  static const groups = <IconGroup>[
    IconGroup(
      id: 'finance',
      label: 'Finanças',
      names: [
        'savings',
        'account_balance',
        'account_balance_wallet',
        'credit_card',
        'paid',
        'attach_money',
        'trending_up',
        'receipt_long',
      ],
    ),
    IconGroup(
      id: 'home',
      label: 'Casa',
      names: [
        'home',
        'house',
        'chair',
        'kitchen',
        'bed',
        'lightbulb',
        'build',
        'yard',
      ],
    ),
    IconGroup(
      id: 'transport',
      label: 'Transporte',
      names: [
        'directions_car',
        'two_wheeler',
        'directions_bus',
        'train',
        'local_gas_station',
        'electric_car',
        'pedal_bike',
        'local_taxi',
      ],
    ),
    IconGroup(
      id: 'travel',
      label: 'Viagem',
      names: [
        'flight',
        'flight_takeoff',
        'luggage',
        'beach_access',
        'hotel',
        'map',
        'explore',
        'sailing',
      ],
    ),
    IconGroup(
      id: 'health',
      label: 'Saúde',
      names: [
        'favorite',
        'fitness_center',
        'local_hospital',
        'medical_services',
        'spa',
        'self_improvement',
        'medication',
        'monitor_heart',
      ],
    ),
    IconGroup(
      id: 'education',
      label: 'Educação',
      names: [
        'school',
        'menu_book',
        'science',
        'calculate',
        'laptop_chromebook',
        'language',
        'psychology',
        'history_edu',
      ],
    ),
    IconGroup(
      id: 'leisure',
      label: 'Lazer',
      names: [
        'sports_esports',
        'movie',
        'music_note',
        'theaters',
        'sports_soccer',
        'celebration',
        'camera_alt',
        'restaurant',
      ],
    ),
    IconGroup(
      id: 'shopping',
      label: 'Compras',
      names: [
        'shopping_cart',
        'shopping_bag',
        'storefront',
        'local_mall',
        'checkroom',
        'redeem',
        'local_offer',
        'diamond',
      ],
    ),
    IconGroup(
      id: 'tech',
      label: 'Tecnologia',
      names: [
        'smartphone',
        'laptop',
        'headphones',
        'watch',
        'tv',
        'computer',
        'videogame_asset',
        'memory',
      ],
    ),
    IconGroup(
      id: 'family',
      label: 'Família',
      names: [
        'family_restroom',
        'child_care',
        'pets',
        'cake',
        'volunteer_activism',
        'escalator_warning',
        'stroller',
        'elderly',
      ],
    ),
  ];

  /// Resolves an API icon name. Unknown or null gives [fallback].
  static IconData resolve(String? name) => _byName[name] ?? fallback;

  // A const map of `Icons.*` keeps icon font tree-shaking working.
  static const _byName = <String, IconData>{
    // finance
    'savings': Icons.savings,
    'account_balance': Icons.account_balance,
    'account_balance_wallet': Icons.account_balance_wallet,
    'credit_card': Icons.credit_card,
    'paid': Icons.paid,
    'attach_money': Icons.attach_money,
    'trending_up': Icons.trending_up,
    'receipt_long': Icons.receipt_long,
    // home
    'home': Icons.home,
    'house': Icons.house,
    'chair': Icons.chair,
    'kitchen': Icons.kitchen,
    'bed': Icons.bed,
    'lightbulb': Icons.lightbulb,
    'build': Icons.build,
    'yard': Icons.yard,
    // transport
    'directions_car': Icons.directions_car,
    'two_wheeler': Icons.two_wheeler,
    'directions_bus': Icons.directions_bus,
    'train': Icons.train,
    'local_gas_station': Icons.local_gas_station,
    'electric_car': Icons.electric_car,
    'pedal_bike': Icons.pedal_bike,
    'local_taxi': Icons.local_taxi,
    // travel
    'flight': Icons.flight,
    'flight_takeoff': Icons.flight_takeoff,
    'luggage': Icons.luggage,
    'beach_access': Icons.beach_access,
    'hotel': Icons.hotel,
    'map': Icons.map,
    'explore': Icons.explore,
    'sailing': Icons.sailing,
    // health
    'favorite': Icons.favorite,
    'fitness_center': Icons.fitness_center,
    'local_hospital': Icons.local_hospital,
    'medical_services': Icons.medical_services,
    'spa': Icons.spa,
    'self_improvement': Icons.self_improvement,
    'medication': Icons.medication,
    'monitor_heart': Icons.monitor_heart,
    // education
    'school': Icons.school,
    'menu_book': Icons.menu_book,
    'science': Icons.science,
    'calculate': Icons.calculate,
    'laptop_chromebook': Icons.laptop_chromebook,
    'language': Icons.language,
    'psychology': Icons.psychology,
    'history_edu': Icons.history_edu,
    // leisure
    'sports_esports': Icons.sports_esports,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'theaters': Icons.theaters,
    'sports_soccer': Icons.sports_soccer,
    'celebration': Icons.celebration,
    'camera_alt': Icons.camera_alt,
    'restaurant': Icons.restaurant,
    // shopping
    'shopping_cart': Icons.shopping_cart,
    'shopping_bag': Icons.shopping_bag,
    'storefront': Icons.storefront,
    'local_mall': Icons.local_mall,
    'checkroom': Icons.checkroom,
    'redeem': Icons.redeem,
    'local_offer': Icons.local_offer,
    'diamond': Icons.diamond,
    // tech
    'smartphone': Icons.smartphone,
    'laptop': Icons.laptop,
    'headphones': Icons.headphones,
    'watch': Icons.watch,
    'tv': Icons.tv,
    'computer': Icons.computer,
    'videogame_asset': Icons.videogame_asset,
    'memory': Icons.memory,
    // family
    'family_restroom': Icons.family_restroom,
    'child_care': Icons.child_care,
    'pets': Icons.pets,
    'cake': Icons.cake,
    'volunteer_activism': Icons.volunteer_activism,
    'escalator_warning': Icons.escalator_warning,
    'stroller': Icons.stroller,
    'elderly': Icons.elderly,
  };
}
