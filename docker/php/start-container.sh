#!/usr/bin/env bash

# Only run migrations if AUTO_MIGRATE is set to true
if [ "${AUTO_MIGRATE}" = "true" ]; then
    echo "Running migrations..."
    php artisan migrate --no-interaction -vvv --force
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

