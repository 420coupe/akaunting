# =============================================================================
# Stage 1: Node — compile frontend assets
# =============================================================================
FROM node:20-alpine AS node-builder

# Upgrade Alpine packages to patch OS-level vulnerabilities
# Install build tools required by node-sass (native C++ addon)
RUN apk upgrade --no-cache \
    && apk add --no-cache python3 make g++

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY webpack.mix.js tailwind.config.js presets.js safelist.txt ./
COPY resources/ resources/
COPY public/ public/

RUN npm run production

# =============================================================================
# Stage 2: Composer — install PHP dependencies
# =============================================================================
FROM php:8.4-cli-alpine AS composer-builder

# Upgrade Alpine packages to patch OS-level vulnerabilities
RUN apk upgrade --no-cache

# install-php-extensions handles all Alpine package resolution automatically
ADD --chmod=0755 \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    /usr/local/bin/

RUN install-php-extensions \
        bcmath ctype dom gd intl mbstring pdo pdo_pgsql tokenizer xml zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Also need git/unzip for composer
RUN apk add --no-cache git unzip

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist \
    --optimize-autoloader

COPY . .
RUN composer dump-autoload --optimize --no-dev

# =============================================================================
# Stage 3: Runtime — PHP 8.4-FPM
# =============================================================================
FROM php:8.4-fpm-alpine AS runtime

# Upgrade Alpine packages to patch OS-level vulnerabilities
RUN apk upgrade --no-cache

# install-php-extensions handles all Alpine package resolution automatically
ADD --chmod=0755 \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    /usr/local/bin/

RUN apk add --no-cache bash curl \
    && install-php-extensions \
        bcmath ctype dom fileinfo gd intl mbstring opcache pdo pdo_pgsql tokenizer xml zip redis \
    && rm -rf /var/cache/apk/*

WORKDIR /var/www/html

# Copy application from composer-builder (includes vendor/)
COPY --from=composer-builder --chown=www-data:www-data /app ./

# Overwrite public/ with compiled assets from node-builder
COPY --from=node-builder --chown=www-data:www-data /app/public ./public

# Copy Docker-specific config files
COPY docker/php/php.ini /usr/local/etc/php/conf.d/akaunting.ini
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Ensure writable directories exist with correct ownership
RUN mkdir -p \
        storage/app/public \
        storage/app/uploads \
        storage/app/temp \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
        bootstrap/cache \
    && chown -R www-data:www-data \
        storage \
        bootstrap/cache \
    && chmod -R 775 \
        storage \
        bootstrap/cache

EXPOSE 9000

USER www-data

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]

# =============================================================================
# Stage 4: Nginx — static asset serving + FastCGI proxy to PHP-FPM
# =============================================================================
FROM nginx:stable-alpine AS nginx-runtime

# Copy compiled public assets from the runtime stage (not node-builder directly).
# This guarantees nginx always serves the exact same JS/CSS as the app container
# and eliminates the parallel build race where nginx could grab a stale cache.
COPY --from=runtime /var/www/html/public /var/www/html/public

# Belt-and-suspenders: copy public/vendor/ directly from the build context.
# This ensures .dockerignore can never accidentally strip public/vendor/ — if it
# did, the build would FAIL loudly here instead of silently 404ing at runtime.
COPY public/vendor/ /var/www/html/public/vendor/

# serviceworker.js and manifest.json live at project root but must be served from public/
COPY serviceworker.js /var/www/html/public/serviceworker.js
COPY manifest.json /var/www/html/public/manifest.json
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
