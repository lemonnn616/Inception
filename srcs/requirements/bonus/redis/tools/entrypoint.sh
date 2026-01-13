#!/usr/bin/env bash
set -euo pipefail

REDIS_PW="$(tr -d '\n' </run/secrets/redis_password)"

cat > /etc/redis/redis.conf <<EOF
bind 0.0.0.0
port 6379
protected-mode yes
requirepass "${REDIS_PW}"
appendonly no
maxmemory 64mb
maxmemory-policy allkeys-lru
daemonize no
EOF

exec redis-server /etc/redis/redis.conf
