#!/usr/bin/env bash

php artisan migrate --no-interaction -vvv --force

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

