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
FROM us-docker.pkg.dev/quickstart-1581571807512/ftas-base-images/ftas-php-82-apache
WORKDIR /app
COPY . /app

COPY --from=frontend /app/public /app/public
RUN chown -R www-data: /app && \
  find /app -type d -exec chmod 0755 {} \; && \
  find /app -type f -exec chmod 0644 {} \; && \
  sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf && \
  sed -ri -e 's!/var/www/html!${APACHE_ROOT}!g' /etc/apache2/sites-available/*.conf /etc/apache2/apache2.conf


COPY --from=vendor /app/vendor/ /app/vendor/

