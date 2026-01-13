#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${DOMAIN_NAME:-localhost}"

cat >/etc/nginx/conf.d/site.conf <<'NGINX'
server {
  listen 443 ssl http2;
  server_name DOMAIN_NAME;

  ssl_certificate     /etc/nginx/certs/fullchain.crt;
  ssl_certificate_key /etc/nginx/certs/privkey.key;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_prefer_server_ciphers on;

  root /var/www/html;
  index index.php;
  client_max_body_size 25m;

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param SCRIPT_NAME     $fastcgi_script_name;
    fastcgi_pass wordpress:9000;
  }

  location = /adminer { return 301 /adminer/; }

  location = /adminer/ {
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME /var/www/adminer/index.php;
    fastcgi_param SCRIPT_NAME     /adminer/index.php;
    fastcgi_pass adminer:9000;
  }

  location ~ ^/adminer/(.+\.php)$ {
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME /var/www/adminer/$1;
    fastcgi_param SCRIPT_NAME     /adminer/$1;
    fastcgi_pass adminer:9000;
  }

  location ^~ /resume/ {
    proxy_pass http://static:8080/;
    proxy_set_header Host               $host;
    proxy_set_header X-Forwarded-Proto  https;
    proxy_set_header X-Forwarded-For    $proxy_add_x_forwarded_for;
  }
}
NGINX

sed -ri "s/DOMAIN_NAME/${DOMAIN}/g" /etc/nginx/conf.d/site.conf
exec nginx -g 'daemon off;'
