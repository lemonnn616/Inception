# Inception

**Inception** is a Docker-based infrastructure project from the 42 / Codam curriculum.  
The goal is to build a complete, reproducible web stack using **Docker Compose**, with strict separation of services, persistent data via volumes, and secure configuration via **Docker secrets**.

This repository contains a full setup with:

- **NGINX** (TLS reverse proxy, HTTPS only)
- **WordPress** (PHP-FPM + WP-CLI bootstrap)
- **MariaDB** (database)
- Bonus services:
  - **Redis** (WordPress object cache)
  - **Adminer** (DB web UI, proxied behind NGINX)
  - **FTP (vsftpd)** (upload to WordPress volume)
  - **Static site** (separate container, proxied at `/resume/`)
  - **Backup service** (DB dumps + WP files архив по cron + retention)

---

## 🧱 Architecture overview

All containers run on a dedicated Docker network:

- Network: `inception` (bridge)
- Persistent bind-mount volumes on the host:
  - `db-data`   → `/home/$USER/data/db`
  - `wp-data`   → `/home/$USER/data/wp`
  - `backup-data` → `/home/$USER/data/backup`

Secrets are stored as files (not inside images) and injected at runtime:

- `db_root_password`
- `db_password`
- `wp_admin_password`
- `redis_password`
- `ftp_password`

Service relationships:

- `mariadb` starts first and becomes **healthy**
- `redis` becomes **healthy**
- `wordpress` waits for DB availability, bootstraps WordPress, enables Redis cache
- `nginx` starts after WordPress is healthy and serves everything over **HTTPS**
- Bonus services run inside the same network and are proxied/used as needed

---

## 📦 Services

### mariadb
- Debian-based MariaDB container with initialization on first run
- Uses Docker secrets for:
  - root password
  - WordPress DB user password
- Exposes `3306` only inside the Docker network
- Has a healthcheck using `mysqladmin ping`

### wordpress (php-fpm)
- Debian-based PHP-FPM image with required PHP extensions
- Uses `wp-cli` to:
  - download WordPress (if missing)
  - generate `wp-config.php` (if missing)
  - install the site (if not installed)
  - create a secondary user
  - install + enable `redis-cache` plugin
  - inject Redis constants into `wp-config.php`
- Runs PHP-FPM on port `9000`
- Healthcheck uses `cgi-fcgi` locally

### nginx (TLS reverse proxy)
- Debian-based NGINX configured for **TLSv1.2/TLSv1.3**
- Exposes:
  - `443:443`
- Serves:
  - WordPress over FastCGI (`wordpress:9000`)
  - Adminer under `/adminer/` (FastCGI to `adminer:9000`)
  - Static site under `/resume/` (HTTP proxy to `static:8080`)
- Certificates are mounted read-only:
  - `srcs/requirements/nginx/certs/fullchain.crt`
  - `srcs/requirements/nginx/certs/privkey.key`
- Has a healthcheck using `curl` against `https://localhost`

### redis (bonus)
- Protected by password from Docker secret `redis_password`
- Healthcheck pings Redis with auth
- Used by WordPress via `redis-cache` plugin

### adminer (bonus)
- PHP-FPM container serving Adminer
- Not exposed to host directly
- Accessible via NGINX at:
  - `https://<DOMAIN>/adminer/`

### ftp (bonus)
- `vsftpd` configured for:
  - local user login (password from secret `ftp_password`)
  - chroot enabled
  - passive ports: `21200–21210`
- Exposes:
  - `21:21`
  - `21200-21210:21200-21210`
- Mounts WordPress volume so uploads land in `/var/www/html`

### static (bonus)
- Separate NGINX container serving a simple static site on:
  - `8080` (internal)
- Proxied by main NGINX at:
  - `https://<DOMAIN>/resume/`

### backup (bonus)
A dedicated backup container that:
- Dumps MariaDB with `mysqldump` → gz file
- Archives WordPress files → tar.gz
- Stores everything in `/backup` (bind-mounted to host)
- Runs:
  - once at container start (best effort)
  - on a cron schedule (default `03:15` daily)
- Cleans old backups with retention policy (default 7 days)

---

## ⚙️ Requirements

- Docker + Docker Compose v2 (`docker compose`)
- A Linux VM environment (as in the project requirements)
- Open ports on the host:
  - `443` (HTTPS)
  - `21`, `21200–21210` (FTP bonus)

---

## 🔐 Secrets & Certificates

### 🗝️ Secrets

This project expects a `secrets/` directory **next to** `srcs/`:

```text
.
├── secrets
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   ├── redis_password.txt
│   └── ftp_password.txt
└── srcs
    └── docker-compose.yml

```

Each file should contain the secret value (one line).

### TLS certificates
Place your certificate files here:

- `srcs/requirements/nginx/certs/fullchain.crt`
- `srcs/requirements/nginx/certs/privkey.key`

Self-signed certificates are acceptable for local development/testing.

---

## 🧪 Environment configuration (`.env`)

The stack is started with:

- `docker compose -f srcs/docker-compose.yml --env-file srcs/.env`

So `srcs/.env` should define values like:

- `DOMAIN_NAME`
- `MYSQL_DATABASE`
- `MYSQL_USER`
- `WP_URL`
- `WP_TITLE`
- `WP_ADMIN_USER`
- `WP_ADMIN_EMAIL`
- `WP_SECOND_USER`
- `WP_SECOND_EMAIL`
- `WP_REDIS_HOST`
- `WP_REDIS_PORT`

> Note: passwords are not stored in `.env`; they are provided via Docker secrets.

---

## ▶️ Build & Run

### 1) Prepare bind mount directories
The Makefile creates:

- `/home/$USER/data/db`
- `/home/$USER/data/wp`
- `/home/$USER/data/backup`

Run:
    make prepare

### 2) Build and start the stack
    make up

This will:
- init/update MLX42-style submodule equivalent (here: `git submodule update --init --recursive` if used)
- build all images
- start containers in detached mode

### 3) Check status & logs
    make ps
    make logs
    make logs-nginx
    make logs-wordpress
    make logs-mariadb

### 4) Stop / remove
    make stop
    make down

---

## 🌍 Access points

After the stack is up:

- WordPress:
  - `https://<DOMAIN>/`
- Adminer (behind NGINX):
  - `https://<DOMAIN>/adminer/`
- Static site:
  - `https://<DOMAIN>/resume/`
- FTP:
  - host: `<DOMAIN>` (or VM IP)
  - port: `21`
  - passive ports: `21200–21210`
  - user: `ftpuser`
  - password: from `ftp_password` secret

> If you use a custom domain locally, add it to `/etc/hosts` pointing to your VM IP.

---

## 🗃️ Backup commands

### Run backup immediately
    make backup-now

This:
- ensures backup service is running
- executes `/usr/local/bin/backup.sh` inside the container
- prints latest backup files from the host backup directory

### List backup files on the host
    make backup-list

Backup files include:
- `db_<db>_<timestamp>.sql.gz`
- `wp_<timestamp>.tar.gz`

---

## 🧱 Project structure

- `Makefile`  
  Convenience targets to run Compose, manage logs, and trigger backups.

- `srcs/docker-compose.yml`  
  Full stack definition (services, healthchecks, secrets, volumes, network).

- `srcs/requirements/`  
  Dockerfiles, configs, and entrypoints per service:
  - `mariadb/`
  - `wordpress/`
  - `nginx/`
  - `bonus/redis/`
  - `bonus/adminer/`
  - `bonus/ftp/`
  - `bonus/static/`
  - `bonus/backup/`

---

## 🔎 Notes & troubleshooting

### Volume paths
This setup uses bind mounts under `/home/$USER/data/...`.

If your `docker-compose.yml` contains hardcoded paths, update them to match your current user/home.

### WordPress bootstrap is idempotent
The WordPress entrypoint is written to be safe across restarts:
- downloads core only if missing
- creates config only if missing
- installs site only if not installed

### Preview healthchecks
All core services include healthchecks and `depends_on: condition: service_healthy` to enforce correct startup order.

---

## 🧠 What I learned

- Designing a multi-container architecture with strict separation of responsibilities
- Using Docker secrets correctly (no credentials baked into images)
- Handling startup order with healthchecks instead of fragile sleeps
- Bootstrapping WordPress automatically with WP-CLI in an idempotent entrypoint
- Running scheduled jobs inside a container (cron + retention policy)
- Managing persistent data safely with bind-mounted volumes
- Operating and debugging a real stack via logs, exec, and Compose tooling
