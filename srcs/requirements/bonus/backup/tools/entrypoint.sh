#!/usr/bin/env bash
set -euo pipefail

DB_HOST="mariadb"
DB_NAME="${MYSQL_DATABASE:-wordpress}"
DB_USER="${MYSQL_USER:-wp_user}"
DB_PASS="$(tr -d '\n' </run/secrets/db_password)"
BACKUP_DIR="/backup"

RETENTION_DAYS="${RETENTION_DAYS:-7}"
CRON_SCHEDULE="${BACKUP_CRON:-15 3 * * *}"
TZ="${TZ:-UTC}"

ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" >/etc/timezone
mkdir -p "${BACKUP_DIR}"

cat >/usr/local/bin/backup.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail

DB_HOST="${DB_HOST:-mariadb}"
DB_NAME="${DB_NAME:-wordpress}"
DB_USER="${DB_USER:-wp_user}"
DB_PASS_FILE="/run/secrets/db_password"
BACKUP_DIR="/backup"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

ts="$(date +'%F_%H%M%S')"

if [ -f "$DB_PASS_FILE" ]; then
  DB_PASS="$(tr -d '\n' <"$DB_PASS_FILE")"
else
  echo "[backup] ERROR: missing db_password secret" >&2
  exit 1
fi

mysqldump -h "$DB_HOST" -u"$DB_USER" -p"$DB_PASS" \
  --databases "$DB_NAME" --single-transaction --quick --lock-tables=false \
  | gzip -9 > "$BACKUP_DIR/db_${DB_NAME}_${ts}.sql.gz"

tar -C /var/www -czf "$BACKUP_DIR/wp_${ts}.tar.gz" html

find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete

echo "[backup] Done at $ts"
BASH
chmod +x /usr/local/bin/backup.sh

echo "${CRON_SCHEDULE} root DB_HOST=${DB_HOST} DB_NAME=${DB_NAME} DB_USER=${DB_USER} RETENTION_DAYS=${RETENTION_DAYS} /usr/local/bin/backup.sh >>/var/log/cron.log 2>&1" >/etc/cron.d/backup
chmod 0644 /etc/cron.d/backup
touch /var/log/cron.log

(/usr/local/bin/backup.sh || true) >/dev/null 2>&1

exec cron -f
