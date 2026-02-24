# Single-image build: Invoice Ninja app (PHP-FPM) + Nginx
# Replaces docker-compose services: config-writer, server, nginx
#
# Build:  docker build -t invoiceninja .   (optional: --build-arg TAG=latest)
# Run:   docker run -d -p 8080:8080 --env-file .env -v storage_data:/var/www/html/storage -v public_data:/var/www/html/public invoiceninja

ARG TAG=latest
FROM invoiceninja/invoiceninja-debian:${TAG}

USER root

# Install nginx
RUN apt-get update && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*

# Nginx config (from ./nginx/)
COPY nginx/laravel.conf /etc/nginx/conf.d/laravel.conf
COPY nginx/invoiceninja.conf /etc/nginx/conf.d/invoiceninja.conf

# Remove default nginx site so our config is used
RUN rm -f /etc/nginx/conf.d/default.conf

# Ensure www-data can run nginx (pid, log paths)
RUN touch /var/run/nginx.pid && chown -R www-data:www-data /var/run/nginx.pid /var/log/nginx

# Entrypoint: start PHP-FPM in background, then nginx in foreground
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Run as non-root
USER www-data

# Persist storage and public (same as compose volumes)
VOLUME ["/var/www/html/storage", "/var/www/html/public"]

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
