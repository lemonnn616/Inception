#!/usr/bin/env bash
set -euo pipefail

install -d -o root -g root -m 0555 /var/run/vsftpd/empty

grep -qxF "/usr/sbin/nologin" /etc/shells || echo "/usr/sbin/nologin" >> /etc/shells

PW="$(tr -d '\n' </run/secrets/ftp_password)"
echo "ftpuser:${PW}" | chpasswd

mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html || true
chmod -R g+rwX /var/www/html || true

exec /usr/sbin/vsftpd /etc/vsftpd.conf
