# Single-image build: Invoice Ninja app (PHP-FPM) + Nginx
# Replaces docker-compose services: config-writer, server, nginx
#
# Build:  docker build -t invoiceninja .   (optional: --build-arg TAG=latest)
# Run:   docker run -d -p 8080:8080 --env-file .env -v storage_data:/var/www/html/storage -v public_data:/var/www/html/public invoiceninja

ARG TAG=latest
FROM invoiceninja/invoiceninja-debian:${TAG}

USER root

# Install nginx (DEBIAN_FRONTEND=noninteractive avoids debconf warnings in CI/Dokploy)
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*

# Nginx config (from ./nginx/)
COPY nginx/laravel.conf /etc/nginx/conf.d/laravel.conf
COPY nginx/invoiceninja.conf /etc/nginx/conf.d/invoiceninja.conf

# Remove default nginx site so our config is used
RUN rm -f /etc/nginx/conf.d/default.conf

# Ensure www-data can run nginx (pid, log, and temp paths under /tmp)
RUN touch /var/run/nginx.pid \
    && mkdir -p /tmp/nginx-body /tmp/nginx-fastcgi /tmp/nginx-proxy /tmp/nginx-uwsgi /tmp/nginx-scgi \
    && chown -R www-data:www-data /var/run/nginx.pid /var/log/nginx /tmp/nginx-body /tmp/nginx-fastcgi /tmp/nginx-proxy /tmp/nginx-uwsgi /tmp/nginx-scgi

# Pristine public from base image (entrypoint copies this into the volume on every start)
RUN mkdir -p /opt/invoiceninja-public && cp -a /var/www/html/public/. /opt/invoiceninja-public/

# Pristine storage structure from base image (entrypoint copies into volume only when empty)
RUN mkdir -p /opt/invoiceninja-storage && cp -a /var/www/html/storage/. /opt/invoiceninja-storage/

# Entrypoint: sync public + init storage when empty, then start PHP-FPM and nginx
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Entrypoint runs as root to restore public; it then runs services as www-data
USER root

# Persist storage and public (same as compose volumes)
VOLUME ["/var/www/html/storage", "/var/www/html/public"]

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
