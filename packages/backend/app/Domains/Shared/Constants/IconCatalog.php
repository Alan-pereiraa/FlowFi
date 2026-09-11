<?php

namespace App\Domains\Shared\Constants;

final class IconCatalog
{
    public const array CATEGORIES = [
        'finance' => [
            'savings',
            'account_balance',
            'account_balance_wallet',
            'credit_card',
            'paid',
            'attach_money',
            'trending_up',
            'receipt_long',
        ],
        'home' => [
            'home',
            'house',
            'chair',
            'kitchen',
            'bed',
            'lightbulb',
            'build',
            'yard',
        ],
        'transport' => [
            'directions_car',
            'two_wheeler',
            'directions_bus',
            'train',
            'local_gas_station',
            'electric_car',
            'pedal_bike',
            'local_taxi',
        ],
        'travel' => [
            'flight',
            'flight_takeoff',
            'luggage',
            'beach_access',
            'hotel',
            'map',
            'explore',
            'sailing',
        ],
        'health' => [
            'favorite',
            'fitness_center',
            'local_hospital',
            'medical_services',
            'spa',
            'self_improvement',
            'medication',
            'monitor_heart',
        ],
        'education' => [
            'school',
            'menu_book',
            'science',
            'calculate',
            'laptop_chromebook',
            'language',
            'psychology',
            'history_edu',
        ],
        'leisure' => [
            'sports_esports',
            'movie',
            'music_note',
            'theaters',
            'sports_soccer',
            'celebration',
            'camera_alt',
            'restaurant',
        ],
        'shopping' => [
            'shopping_cart',
            'shopping_bag',
            'storefront',
            'local_mall',
            'checkroom',
            'redeem',
            'local_offer',
            'diamond',
        ],
        'tech' => [
            'smartphone',
            'laptop',
            'headphones',
            'watch',
            'tv',
            'computer',
            'videogame_asset',
            'memory',
        ],
        'family' => [
            'family_restroom',
            'child_care',
            'pets',
            'cake',
            'volunteer_activism',
            'escalator_warning',
            'stroller',
            'elderly',
        ],
    ];

    public static function names(): array
    {
        return array_merge(...array_values(self::CATEGORIES));
    }
}
