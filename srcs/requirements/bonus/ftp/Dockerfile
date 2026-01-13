FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      vsftpd ca-certificates libpam-modules \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /var/www/html -s /usr/sbin/nologin ftpuser || true \
 && groupadd -g 33 -f www-data || true \
 && usermod -a -G www-data ftpuser

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 21 21200-21210
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
