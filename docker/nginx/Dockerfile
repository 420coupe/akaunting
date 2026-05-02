# =============================================================================
# Nginx service Dockerfile
#
# Intentionally separate from the main PHP Dockerfile so that this build has
# its own isolated BuildKit cache.  When docker-compose builds all services in
# parallel, the main Dockerfile's node-builder cache can be in a race with this
# one; keeping them separate eliminates that race: each Dockerfile has its own
# content-addressed cache chain and will correctly miss cache whenever
# resources/ changes, regardless of what the PHP build is doing in parallel.
# =============================================================================

# Stage 1: Compile frontend assets
# ---------------------------------------------------------------------------
FROM node:20-alpine AS node-builder

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
# Stage 2: Nginx runtime — serves compiled static assets
# =============================================================================
FROM nginx:stable-alpine

COPY --from=node-builder /app/public /var/www/html/public

# public/vendor/ is not compiled by webpack; copy directly from build context
# so it's always present even if .dockerignore excludes it from the node stage.
COPY public/vendor/ /var/www/html/public/vendor/

COPY serviceworker.js /var/www/html/public/serviceworker.js
COPY manifest.json /var/www/html/public/manifest.json
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
