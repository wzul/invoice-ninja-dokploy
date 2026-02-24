#!/bin/sh
set -e

# Always copy fresh public files from invoiceninja-debian image into the volume
cp -a /opt/invoiceninja-public/. /var/www/html/public/
chown -R www-data:www-data /var/www/html/public

# If storage volume is empty (first run), copy structure from image so Laravel has framework/logs/app dirs
if [ ! -d /var/www/html/storage/framework ] || [ ! -d /var/www/html/storage/logs ]; then
  cp -a /opt/invoiceninja-storage/. /var/www/html/storage/
  chown -R www-data:www-data /var/www/html/storage
fi

# Start PHP-FPM as root (master opens logs/socket; workers run as www-data per pool config)
php-fpm &

# Run nginx as www-data (replaces this process)
exec su -s /bin/sh www-data -c "nginx -g 'daemon off;'"
