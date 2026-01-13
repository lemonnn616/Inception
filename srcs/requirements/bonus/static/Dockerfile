FROM debian:12-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx ca-certificates \
 && rm -rf /var/lib/apt/lists/*
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY www/ /var/www/static/
EXPOSE 8080
CMD ["nginx","-g","daemon off;"]
