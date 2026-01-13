FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      php-fpm php-mysql php-cli php-curl php-xml php-mbstring php-zip php-gd php-redis \
      curl ca-certificates less unzip mariadb-client libfcgi-bin \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp \
 && chmod +x /usr/local/bin/wp

RUN sed -ri 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/*/fpm/pool.d/www.conf \
 && sed -ri 's|;?clear_env = .*|clear_env = no|' /etc/php/*/fpm/pool.d/www.conf \
 && sed -ri 's|;?catch_workers_output = .*|catch_workers_output = yes|' /etc/php/*/fpm/pool.d/www.conf

RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html
WORKDIR /var/www/html

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=20s \
  CMD cgi-fcgi -bind -connect 127.0.0.1:9000 >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
