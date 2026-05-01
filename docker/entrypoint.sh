#!/bin/bash
set -e

APP_DIR="/var/www/html"

# ─── Helpers ──────────────────────────────────────────────────────────────────
log() { echo "[entrypoint] $*"; }

# ─── Wait for Supabase Postgres ───────────────────────────────────────────────
wait_for_db() {
    log "Waiting for database connection..."
    log "  DB_HOST=${DB_HOST} DB_PORT=${DB_PORT:-5432} DB_DATABASE=${DB_DATABASE} DB_USERNAME=${DB_USERNAME} DB_SSLMODE=${DB_SSLMODE:-require}"
    local retries=30
    until php -r "
        \$dsn = 'pgsql:host=${DB_HOST};port=${DB_PORT:-5432};dbname=${DB_DATABASE};sslmode=${DB_SSLMODE:-require}';
        try {
            new PDO(\$dsn, '${DB_USERNAME}', '${DB_PASSWORD}');
            echo 'OK';
        } catch (Exception \$e) {
            fwrite(STDERR, \$e->getMessage() . PHP_EOL);
        }
    " 2>&1 | tee /tmp/db_error.txt | grep -q OK; do
        retries=$((retries - 1))
        if [ "$retries" -le 0 ]; then
            log "ERROR: Could not connect to database after 30 attempts. Last error: $(cat /tmp/db_error.txt 2>/dev/null)"
            exit 1
        fi
        log "Database not ready yet — retrying in 3s ($retries attempts left)... Error: $(cat /tmp/db_error.txt 2>/dev/null | head -1)"
        sleep 3
    done
    log "Database connection established."
}

# ─── Generate APP_KEY if missing ─────────────────────────────────────────────
generate_key() {
    if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:" ]; then
        log "APP_KEY is empty — generating a new key..."
        php "$APP_DIR/artisan" key:generate --force --no-interaction
        log "APP_KEY generated. Copy it from storage and persist it as an env var."
    fi
}

# ─── Run migrations / first-time install ─────────────────────────────────────
run_migrations() {
    if [ "${APP_INSTALLED:-false}" = "false" ]; then
        log "First-time install detected (APP_INSTALLED=false)."
        log "Running: php artisan install ..."
        php "$APP_DIR/artisan" install \
            --db-host="${DB_HOST}" \
            --db-port="${DB_PORT:-5432}" \
            --db-name="${DB_DATABASE}" \
            --db-username="${DB_USERNAME}" \
            --db-password="${DB_PASSWORD}" \
            --db-prefix="${DB_PREFIX:-}" \
            --company-name="${COMPANY_NAME:-My Company}" \
            --company-email="${COMPANY_EMAIL:-admin@example.com}" \
            --admin-email="${ADMIN_EMAIL:-admin@example.com}" \
            --admin-password="${ADMIN_PASSWORD:-ChangeMe!}" \
            --locale="${APP_LOCALE:-en-GB}" \
            --no-interaction
        log "Install complete. Set APP_INSTALLED=true in your env vars and restart."
    else
        log "Running migrations..."
        php "$APP_DIR/artisan" migrate --force --no-interaction
    fi
}

# ─── Storage symlink ──────────────────────────────────────────────────────────
link_storage() {
    if [ ! -L "$APP_DIR/public/storage" ]; then
        log "Creating storage symlink..."
        php "$APP_DIR/artisan" storage:link --force --no-interaction
    fi
}

# ─── Laravel caches ──────────────────────────────────────────────────────────
cache_config() {
    log "Caching config and views..."
    php "$APP_DIR/artisan" config:cache --no-interaction
    # route:cache is intentionally skipped: Akaunting's {company_id}/livewire/update
    # route conflicts with Livewire's livewire.update route name and causes serialization failure.
    php "$APP_DIR/artisan" view:cache   --no-interaction
}

# ─── Main ─────────────────────────────────────────────────────────────────────
wait_for_db
generate_key
run_migrations
link_storage
cache_config

log "Starting: $*"
exec "$@"
