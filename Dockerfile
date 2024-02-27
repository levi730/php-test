#################################################
# Composer Setup
#################################################
FROM composer:2.6 as vendor
COPY database/ database/

COPY composer.json composer.json
COPY composer.lock composer.lock



RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist

#################################################
# NodeJS Setup
#################################################
FROM node:18 as frontend
RUN mkdir -p /app/public
COPY package.json vite.config.js package-lock.json /app/
COPY resources /app/resources

WORKDIR /app
RUN npm install && npm run build


#################################################
# PHP/Apache Setup
#################################################
FROM php:8.2-apache
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN mkdir -p /app && \
    a2enmod rewrite
WORKDIR /app
COPY . /app
COPY --from=vendor /app/vendor/ /app/vendor/
COPY --from=frontend /app/public /app/public

# Configure PHP for Cloud Run.
# Precompile PHP code with opcache.
#RUN docker-php-ext-install -j "$(nproc)" opcache
#RUN set -ex; \
#  { \
#    echo "; Cloud Run enforces memory & timeouts"; \
#    echo "memory_limit = -1"; \
#    echo "max_execution_time = 0"; \
#    echo "; File upload at Cloud Run network limit"; \
#    echo "upload_max_filesize = 32M"; \
#    echo "post_max_size = 32M"; \
#    echo "; Configure Opcache for Containers"; \
#    echo "opcache.enable = On"; \
#    echo "opcache.validate_timestamps = Off"; \
#    echo "; Configure Opcache Memory (Application-specific)"; \
#    echo "opcache.memory_consumption = 32"; \
#  } > "$PHP_INI_DIR/conf.d/cloud-run.ini"

RUN install-php-extensions pdo_mysql gd zip sqlsrv pdo_sqlsrv \
    && php artisan optimize
COPY --chown=www-data:www-data . ./

COPY .docker/apache_config.txt /etc/apache2/sites-available/000-default.conf

# Use the PORT environment variable in Apache configuration files.
# https://cloud.google.com/run/docs/reference/container-contract#port
RUN sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Configure PHP for development.
# Switch to the production php.ini for production operations.
# RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
# https://github.com/docker-library/docs/blob/master/php/README.md#configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
