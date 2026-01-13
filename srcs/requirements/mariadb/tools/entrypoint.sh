#!/usr/bin/env bash
set -euo pipefail

ROOT_PW="$(tr -d '\n' </run/secrets/db_root_password)"
USER_PW="$(tr -d '\n' </run/secrets/db_password)"
DB="${MYSQL_DATABASE:-wordpress}"
USER="${MYSQL_USER:-wp_user}"

chown -R mysql:mysql /var/lib/mysql /run/mysqld

if [ ! -d /var/lib/mysql/mysql ]; then
  echo "[mariadb] initializing database..."
  mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql --skip-test-db >/dev/null

  cat >/tmp/init.sql <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PW}';
CREATE DATABASE IF NOT EXISTS \`${DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${USER}'@'%' IDENTIFIED BY '${USER_PW}';
GRANT ALL PRIVILEGES ON \`${DB}\`.* TO '${USER}'@'%';
FLUSH PRIVILEGES;
SQL

  mysqld --user=mysql --datadir=/var/lib/mysql \
         --skip-networking=1 \
         --socket=/run/mysqld/mysqld.sock \
         --bootstrap < /tmp/init.sql
  rm -f /tmp/init.sql
fi

echo "[mariadb] starting mysqld..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --skip-name-resolve
