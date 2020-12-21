FROM php:7.4-fpm-alpine

LABEL maintainer="Adam Jarvis <adam@jarvis.gg>"

RUN set -ex

RUN apk update; \
    apk upgrade; \
    apk add --no-cache \
    fcgi \
    mariadb-client \
    libpng-dev \
    libmcrypt-dev \
    libjpeg \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    libxml2-dev \
    libmemcached-dev \
    libressl-dev \
    zip \
    unzip \
    wget

# Install PHP pecl deps for installing php modules
RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS imagemagick-dev libtool; \
    export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS"; \
    apk add --no-cache --virtual .imagick-runtime-deps imagemagick

RUN pecl install imagick; \
    pecl install memcached; \
    pecl install redis;

RUN PHP_OPENSSL=yes docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
    echo "extension=memcached.so" >> /usr/local/etc/php/conf.d/memcached.ini;

RUN docker-php-ext-install imap; \
    docker-php-ext-install pdo_mysql; \
    docker-php-ext-install mysqli; \
    docker-php-ext-install opcache; \
    docker-php-ext-install soap; \
    docker-php-ext-install zip; \
    docker-php-ext-install exif; \
    docker-php-ext-install gd; \
    docker-php-ext-install zip; \
    docker-php-ext-install opcache

RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/; \
    docker-php-ext-configure zip; \
    docker-php-ext-enable imagick;

# clear up php pecl deps
RUN apk del .phpize-deps

    # set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Install health check tool for use in container health check
# https://github.com/renatomefi/php-fpm-healthcheck
RUN wget -O /usr/local/bin/php-fpm-healthcheck \
    https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck

# Enable php fpm status page
RUN echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.d/zz-docker.conf

