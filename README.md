# Akaunting™

[![Release](https://img.shields.io/github/v/release/akaunting/akaunting?label=release)](https://github.com/akaunting/akaunting/releases)
![Downloads](https://img.shields.io/github/downloads/akaunting/akaunting/total?label=downloads)
[![Translations](https://badges.crowdin.net/akaunting/localized.svg)](https://crowdin.com/project/akaunting)
[![Tests](https://img.shields.io/github/actions/workflow/status/akaunting/akaunting/tests.yml?label=tests)](https://github.com/akaunting/akaunting/actions)

Online accounting software designed for small businesses and freelancers. Akaunting is built with modern technologies such as Laravel, VueJS, Tailwind, RESTful API etc. Thanks to its modular structure, Akaunting provides an awesome App Store for users and developers.

- [Home](https://akaunting.com) - The house of Akaunting
- [Forum](https://akaunting.com/forum) - Ask for support
- [Documentation](https://akaunting.com/hc/docs) - Learn how to use
- [Developer Portal](https://developer.akaunting.com) - Generate passive income
- [App Store](https://akaunting.com/apps) - Extend your Akaunting
- [Translations](https://crowdin.com/project/akaunting) - Help us translate Akaunting

## Requirements

- PHP 8.1 or higher
- Database (e.g.: MariaDB, MySQL, PostgreSQL, SQLite)
- Web Server (eg: Apache, Nginx, IIS)
- [Other libraries](https://akaunting.com/hc/docs/on-premise/requirements/)

## Framework

Akaunting uses [Laravel](http://laravel.com), the best existing PHP framework, as the foundation framework and [Module](https://github.com/akaunting/module) package for Apps.

## Installation

Before installing Akaunting, make sure your environment has the required dependencies installed:

- PHP 8.1 or higher with the required PHP extensions
- Composer
- Node.js and npm
- Git
- A supported database server, such as MariaDB, MySQL, PostgreSQL, or SQLite
- A web server, such as Apache, Nginx, or IIS
- Build tools required by some npm packages, such as `build-essential` on Debian/Ubuntu systems

For the full list of PHP extensions and server requirements, see the [on-premise requirements](https://akaunting.com/hc/docs/on-premise/requirements/).

Then install Akaunting:

- Clone the repository: `git clone https://github.com/akaunting/akaunting.git`
- Install dependencies: `composer install ; npm install ; npm run dev`
- Install Akaunting:

```bash
php artisan install --db-name="akaunting" --db-username="root" --db-password="pass" --admin-email="admin@company.com" --admin-password="123456"
```

- Create sample data (optional): `php artisan sample-data:seed`

## Docker Deployment

This repository includes a production-ready Docker setup targeting a self-hosted environment with:

- **PHP 8.4-FPM** (Alpine, hardened with `apk upgrade`)
- **Nginx** sidecar (static assets + FastCGI proxy)
- **Redis** (cache, sessions, queues)
- **Supabase Postgres** (external managed database)
- **Supabase Storage** (S3-compatible file storage)
- **Nginx Proxy Manager** (external SSL termination)

### Stack overview

```
Internet → NPM (HTTPS) → nginx:80 → app:9000 (PHP-FPM)
                                        ↕
                                 Redis (internal)
                                        ↕
                               Supabase Postgres (external)

worker  → queue:work (async jobs)
cron    → schedule:run every 60s (reminders, recurring checks)
uploads → Supabase Storage (S3)
```

### Files

| File                        | Purpose                                                               |
| --------------------------- | --------------------------------------------------------------------- |
| `Dockerfile`                | Multi-stage build: Node 22 (assets) → Composer (vendor) → PHP 8.4-FPM |
| `docker-compose.yml`        | Defines `app`, `nginx`, `redis`, `worker`, `cron` services            |
| `docker/nginx/default.conf` | Nginx config with security rules and FastCGI proxy                    |
| `docker/php/php.ini`        | Production PHP settings and OPcache config                            |
| `docker/entrypoint.sh`      | Startup logic: DB wait, key gen, install/migrate, cache warm          |
| `.dockerignore`             | Excludes dev artefacts from build context                             |
| `.env.docker.example`       | Environment variable template                                         |

### First-time setup

**Prerequisites**

- Supabase project with an empty Postgres database
- Supabase Storage bucket named `akaunting` with S3 access keys enabled
- Nginx Proxy Manager running with its `nginxproxymanager_default` Docker network

**1. Configure environment**

Copy `.env.docker.example` into Portainer's stack environment variables and fill in all `<CHANGE_ME>` fields:

```
DB_HOST, DB_PASSWORD          — Supabase Postgres connection
AWS_ACCESS_KEY_ID/SECRET      — Supabase Storage S3 keys
AWS_ENDPOINT                  — https://<project-ref>.supabase.co/storage/v1/s3
SENDGRID_API_KEY              — SendGrid API key
APP_URL                       — Your public HTTPS domain
COMPANY_NAME/EMAIL            — First company details
ADMIN_EMAIL/PASSWORD          — Admin login credentials
```

Leave `APP_KEY=` empty and `APP_INSTALLED=false` for first boot.

**2. Deploy**

In Portainer, create a new Git-synced stack pointing at this repository. The entrypoint handles the rest automatically:

1. Waits for Supabase DB to accept connections
2. Generates `APP_KEY` if empty
3. Runs `php artisan install` (creates tables, seeds permissions, creates company + admin)
4. Creates the `public/storage` symlink
5. Warms config, route, and view caches
6. Starts PHP-FPM

**3. After first boot**

```bash
# Retrieve the generated APP_KEY
docker exec akaunting-app php artisan key:generate --show
```

Paste the output into Portainer as `APP_KEY`, then set `APP_INSTALLED=true` and update the stack.

**4. NPM proxy host**

In Nginx Proxy Manager, add a proxy host:

- **Domain**: your public domain
- **Forward hostname**: `akaunting-nginx`
- **Forward port**: `80`
- Enable SSL with Let's Encrypt

### Environment variable reference

| Variable            | Description                                              |
| ------------------- | -------------------------------------------------------- |
| `APP_KEY`           | Laravel encryption key — generate once, never change     |
| `APP_INSTALLED`     | Set to `true` after first successful install             |
| `APP_LOCALE`        | Default UI language/locale (e.g. `en-GB`, `en-US`)       |
| `APP_SCHEDULE_TIME` | Time (UTC, 24h) for daily reminders and recurring checks |
| `DB_PREFIX`         | Table prefix — default `ak_`, set before first boot only |
| `TRUSTED_PROXIES`   | Set to `*` when running behind Nginx Proxy Manager       |
| `FILESYSTEM_DISK`   | Set to `s3` for Supabase Storage                         |

## Contributing

Please, be very clear on your commit messages and Pull Requests, empty Pull Request messages may be rejected without reason.

When contributing code to Akaunting, you must follow the PSR coding standards. The golden rule is: Imitate the existing Akaunting code.

Please note that this project is released with a [Contributor Code of Conduct](https://akaunting.com/conduct). _By participating in this project you agree to abide by its terms_.

## Translation

If you'd like to contribute translations, please check out our [Crowdin](https://crowdin.com/project/akaunting) project.

## Changelog

Please see [Releases](../../releases) for more information about what has changed recently.

## Security

Please review [our security policy](https://github.com/akaunting/akaunting/security/policy) on how to report security vulnerabilities.

## Credits

- [Denis Duliçi](https://github.com/denisdulici)
- [Cüneyt Şentürk](https://github.com/cuneytsenturk)
- [All Contributors](../../contributors)

## License

Akaunting is released under the [BSL license](LICENSE.txt).
