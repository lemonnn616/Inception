FROM debian:12-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx curl ca-certificates gettext-base openssl \
 && rm -rf /var/lib/apt/lists/*
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
EXPOSE 443
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
