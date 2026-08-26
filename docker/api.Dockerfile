FROM php:8.3-cli

# git + unzip for composer; the official php image already ships every
# extension Laravel needs here, including pdo_sqlite.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

COPY api-entrypoint.sh /usr/local/bin/api-entrypoint.sh
RUN chmod +x /usr/local/bin/api-entrypoint.sh

WORKDIR /app

EXPOSE 8000

ENTRYPOINT ["api-entrypoint.sh"]
