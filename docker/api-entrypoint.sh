#!/bin/sh
set -e

cd /app

composer install --no-interaction

if [ ! -f .env ]; then
    cp .env.example .env
fi

if ! grep -q '^APP_KEY=.\{1,\}' .env; then
    php artisan key:generate --force
fi

if [ ! -f database/database.sqlite ]; then
    touch database/database.sqlite
fi

php artisan migrate --force

exec php artisan serve --host=0.0.0.0 --port=8000
