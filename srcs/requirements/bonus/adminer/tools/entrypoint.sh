#!/usr/bin/env sh
set -eu

sed -ri 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/*/fpm/pool.d/www.conf
sed -ri 's|;?clear_env = .*|clear_env = no|'     /etc/php/*/fpm/pool.d/www.conf

PHPFPM_BIN="$(command -v php-fpm || true)"
[ -z "$PHPFPM_BIN" ] && [ -x /usr/sbin/php-fpm8.2 ] && PHPFPM_BIN=/usr/sbin/php-fpm8.2
[ -z "$PHPFPM_BIN" ] && [ -x /usr/sbin/php-fpm7.4 ] && PHPFPM_BIN=/usr/sbin/php-fpm7.4

if [ -z "$PHPFPM_BIN" ]; then
  echo "[adminer] php-fpm binary not found" >&2
  ls -l /usr/sbin/php-fpm* /usr/bin/php-fpm* 2>/dev/null || true
  exit 127
fi

echo "[adminer] starting $PHPFPM_BIN ..."
exec "$PHPFPM_BIN" -F
