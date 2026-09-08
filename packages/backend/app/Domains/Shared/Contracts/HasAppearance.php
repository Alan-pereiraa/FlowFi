<?php

namespace App\Domains\Shared\Contracts;

/**
 * An Eloquent model that carries a user-picked icon and color.
 *
 * Implementors must have fillable `icon` (a name from IconCatalog) and
 * `color` (`#RRGGBB`) attributes; AppearanceService writes them.
 *
 * @property string $icon
 * @property string $color
 */
interface HasAppearance {}
