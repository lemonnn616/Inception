FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      php-fpm php-mysql curl ca-certificates libfcgi-bin \
 && rm -rf /var/lib/apt/lists/*

RUN sed -ri 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/*/fpm/pool.d/www.conf \
 && sed -ri 's|;?clear_env = .*|clear_env = no|' /etc/php/*/fpm/pool.d/www.conf

RUN mkdir -p /var/www/adminer \
 && curl -fsSL https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php \
      -o /var/www/adminer/index.php \
 && chown -R www-data:www-data /var/www/adminer

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD cgi-fcgi -bind -connect 127.0.0.1:9000 >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
