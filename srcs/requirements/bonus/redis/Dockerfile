FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends redis-server redis-tools ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /etc/redis

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 6379

HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=10s \
  CMD sh -c 'PW="$(tr -d \"\\n\" </run/secrets/redis_password)"; redis-cli -a "$PW" ping | grep -q PONG' || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
