#!/usr/bin/env bash
set -euo pipefail

DB_PASS="$(tr -d '\n' </run/secrets/db_password)"
DB_NAME="${MYSQL_DATABASE:-wordpress}"
DB_USER="${MYSQL_USER:-wp_user}"
DB_HOST="mariadb:3306"

WP_URL="${WP_URL:?WP_URL is required}"
WP_TITLE="${WP_TITLE:-Inception}"
WP_ADMIN_USER="${WP_ADMIN_USER:?WP_ADMIN_USER is required}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is required}"
WP_ADMIN_PASS="$(tr -d '\n' </run/secrets/wp_admin_password)"
WP_SECOND_USER="${WP_SECOND_USER:-editor}"
WP_SECOND_EMAIL="${WP_SECOND_EMAIL:-editor@example.com}"

REDIS_HOST="${WP_REDIS_HOST:-redis}"
REDIS_PORT="${WP_REDIS_PORT:-6379}"
REDIS_PASS="$(tr -d '\n' </run/secrets/redis_password 2>/dev/null || true)"

echo "[wp] waiting for MariaDB at ${DB_HOST}..."
ok=0
for i in {1..60}; do
  if mariadb -h "${DB_HOST%%:*}" -u"${DB_USER}" -p"${DB_PASS}" -e "SELECT 1" >/dev/null 2>&1; then
    ok=1; break
  fi
  sleep 2
done
if [ "$ok" -ne 1 ]; then
  echo "[wp] ERROR: DB is not reachable with provided credentials" >&2
  exit 1
fi

if [ ! -f /var/www/html/wp-includes/version.php ]; then
  echo "[wp] downloading WordPress core..."
  wp core download --allow-root --path=/var/www/html
  chown -R www-data:www-data /var/www/html
fi

if [ ! -f /var/www/html/wp-config.php ]; then
  echo "[wp] creating wp-config.php..."
  wp config create \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASS}" \
    --dbhost="${DB_HOST}" \
    --path=/var/www/html \
    --allow-root \
    --skip-check
  wp config shuffle-salts --allow-root --path=/var/www/html
fi

if ! wp core is-installed --allow-root --path=/var/www/html >/dev/null 2>&1; then
  echo "[wp] installing site..."
  wp core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASS}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root \
    --path=/var/www/html

  wp user create "${WP_SECOND_USER}" "${WP_SECOND_EMAIL}" --role=editor --porcelain \
    --allow-root --path=/var/www/html || true
fi

if ! wp plugin is-installed redis-cache --allow-root --path=/var/www/html; then
  wp plugin install redis-cache --activate --allow-root --path=/var/www/html || true
else
  wp plugin activate redis-cache --allow-root --path=/var/www/html || true
fi

wp config delete WP_REDIS_HOST --type=constant --allow-root --path=/var/www/html || true
wp config delete WP_REDIS_PORT --type=constant --allow-root --path=/var/www/html || true
wp config delete WP_REDIS_PASSWORD --type=constant --allow-root --path=/var/www/html || true
wp config delete WP_REDIS_CLIENT --type=constant --allow-root --path=/var/www/html || true

wp config set WP_REDIS_HOST "${REDIS_HOST}" --type=constant --allow-root --path=/var/www/html
wp config set WP_REDIS_PORT "${REDIS_PORT}" --type=constant --allow-root --path=/var/www/html
wp config set WP_REDIS_CLIENT "phpredis" --type=constant --allow-root --path=/var/www/html
[ -n "${REDIS_PASS}" ] && wp config set WP_REDIS_PASSWORD "${REDIS_PASS}" --type=constant --allow-root --path=/var/www/html || true

for i in {1..30}; do
  php -r '
    $h=getenv("REDIS_HOST")?: "redis";
    $p=(int)(getenv("REDIS_PORT")?: "6379");
    $pw=@file_get_contents("/run/secrets/redis_password");
    $pw=$pw===false?"":trim($pw);
    $r=new Redis();
    try{ $r->connect($h,$p,0.5); if(strlen($pw)) $r->auth($pw); echo $r->ping(); } catch(Throwable $e){ echo "ERR"; }
  ' REDIS_HOST="${REDIS_HOST}" REDIS_PORT="${REDIS_PORT}" 2>/dev/null | grep -q PONG && break
  sleep 1
done

wp redis enable --force --allow-root --path=/var/www/html || true

chown -R www-data:www-data /var/www/html

PHP_FPM_BIN="$(command -v php-fpm8.2 || command -v php-fpm)"
exec "${PHP_FPM_BIN}" -F
