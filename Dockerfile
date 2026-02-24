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

# Pristine public from base image (try both common paths; base may use /var/www/app or /var/www/html)
RUN mkdir -p /opt/invoiceninja-public && \
  if [ -d /var/www/html/public ]; then cp -a /var/www/html/public/. /opt/invoiceninja-public/; \
  elif [ -d /var/www/app/public ]; then cp -a /var/www/app/public/. /opt/invoiceninja-public/; fi

# Pristine storage structure from base image
RUN mkdir -p /opt/invoiceninja-storage && \
  if [ -d /var/www/html/storage ]; then cp -a /var/www/html/storage/. /opt/invoiceninja-storage/; \
  elif [ -d /var/www/app/storage ]; then cp -a /var/www/app/storage/. /opt/invoiceninja-storage/; \
  else mkdir -p /opt/invoiceninja-storage/framework/cache /opt/invoiceninja-storage/framework/sessions /opt/invoiceninja-storage/framework/views /opt/invoiceninja-storage/logs /opt/invoiceninja-storage/app/public; fi

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
