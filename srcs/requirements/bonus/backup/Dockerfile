FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      cron mariadb-client ca-certificates tzdata bash coreutils tar gzip procps \
 && rm -rf /var/lib/apt/lists/*

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/backup"]
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
