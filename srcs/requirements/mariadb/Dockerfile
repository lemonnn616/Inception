FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends mariadb-server mariadb-client ca-certificates tzdata \
 && rm -rf /var/lib/apt/lists/*

COPY conf/99-custom.cnf /etc/mysql/mariadb.conf.d/99-custom.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN mkdir -p /var/lib/mysql /run/mysqld \
 && chown -R mysql:mysql /var/lib/mysql /run/mysqld \
 && chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306

HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=20s \
  CMD mysqladmin ping -uroot -p"$(tr -d '\n' </run/secrets/db_root_password)" --silent || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
