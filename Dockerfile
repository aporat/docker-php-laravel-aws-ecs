FROM php:8.4-fpm AS php

# mix
RUN apt-get update \
  && apt-get install -y build-essential supervisor zlib1g-dev default-mysql-client curl gnupg procps vim git unzip libzip-dev libpq-dev libmagickwand-dev

# extensions
RUN docker-php-ext-install pdo
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install opcache
RUN docker-php-ext-install zip
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install bcmath

# intl
RUN apt-get install -y libicu-dev \
  && docker-php-ext-configure intl \
  && docker-php-ext-install intl

# gd
RUN apt-get install -y libicu-dev libmagickwand-dev libmcrypt-dev libcurl3-dev jpegoptim libfreetype6-dev libjpeg62-turbo-dev libpng-dev && \
docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
docker-php-ext-install gd

# crontab
RUN apt-get install -y cron

# redis
RUN pecl install redis && docker-php-ext-enable redis

# pcov
RUN pecl install pcov && docker-php-ext-enable pcov

RUN apt-get install -y nginx
RUN apt-get install -y supervisor

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN addgroup --system --gid 1000 app-group
RUN adduser --system --ingroup app-group --uid 1000 app-user

COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/fastcgi_fpm docker/nginx/gzip_params /etc/nginx/

RUN mkdir -p /var/lib/nginx/tmp /var/log/nginx

# Create PHP session directory
RUN mkdir -p /tmp/sessions && chmod 1777 /tmp/sessions

# cronjob
ADD docker/php/laravel-cronjob /etc/cron.d/laravel-cron
RUN chmod 0644 /etc/cron.d/laravel-cron \
    && crontab -u app-user /etc/cron.d/laravel-cron

RUN chmod gu+rw /var/run

# setup nginx user permissions
RUN chown -R app-user:app-group /var/lib/nginx /var/log/nginx
RUN chown -R app-user:app-group /usr/local/etc/php-fpm.d

# Supervisord
COPY docker/php/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set working directory to /var/app
WORKDIR /var/app

# Copy application sources into the container.
COPY --chown=app-user:app-group laravel /var/app
RUN chown -R app-user:app-group /var/app
RUN chmod +w /var/app/public
RUN chown -R app-user:app-group /var /run

# Create laravel caching folders.
RUN mkdir -p /var/app/storage/framework
RUN mkdir -p /var/app/storage/framework/cache
RUN mkdir -p /var/app/storage/framework/testing
RUN mkdir -p /var/app/storage/framework/sessions
RUN mkdir -p /var/app/storage/framework/views

# Fix files ownership.
RUN chown -R app-user /var/app/storage
RUN chown -R app-user /var/app/storage/framework
RUN chown -R app-user /var/app/storage/framework/sessions

# Set correct permission.
RUN chmod -R 755 /var/app/storage
RUN chmod -R 755 /var/app/storage/logs
RUN chmod -R 755 /var/app/storage/framework
RUN chmod -R 755 /var/app/storage/framework/sessions
RUN chmod -R 755 /var/app/bootstrap

COPY docker/php/start-container.sh /usr/local/bin/start-container
RUN chmod +x /usr/local/bin/start-container

ENV PHP_OPCACHE_ENABLE=1
ENV PHP_OPCACHE_ENABLE_CLI=0
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
ENV PHP_OPCACHE_REVALIDATE_FREQ=0

# php settings
COPY docker/php/php.ini $PHP_INI_DIR/
COPY docker/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY docker/php/opcache.ini $PHP_INI_DIR/conf.d/opcache.ini

COPY docker/nginx/app.conf /etc/nginx/conf.d/app.conf

# development box final config
FROM php AS php_development

ENV PHP_OPCACHE_ENABLE=0
ENV PHP_OPCACHE_ENABLE_CLI=0
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
ENV PHP_OPCACHE_REVALIDATE_FREQ=0

COPY docker/php/opcache.ini $PHP_INI_DIR/conf.d/opcache.ini

# Xdebug
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug

USER app-user

RUN composer install --no-ansi --no-interaction --no-plugins --no-progress --no-scripts --optimize-autoloader

ENTRYPOINT ["/usr/local/bin/start-container"]

# production box final config
FROM php AS php_production

USER app-user

RUN composer install  --no-cache --no-ansi --no-dev --no-interaction --no-plugins --no-progress --no-scripts --optimize-autoloader

ENTRYPOINT ["/usr/local/bin/start-container"]
