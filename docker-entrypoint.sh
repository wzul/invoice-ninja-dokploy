#!/bin/sh
set -e

# Start PHP-FPM in background (same as original server container)
php-fpm &

# Run main process (nginx)
exec "$@"
