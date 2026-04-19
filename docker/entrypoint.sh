#!/bin/bash
# Container entrypoint: apply pending DB migrations, then hand off to Apache.
#
# Retries the connection for up to 60s because Coolify may start the app
# container before MySQL is ready to accept connections. If migrations
# fail, we exit non-zero so the container restarts — better than serving
# traffic against an out-of-date schema.

set -e

MIGRATION_RUNNER=/var/www/html/migrations/apply.php
LOCAL_XML=/var/www/html/app/etc/local.xml

if [ ! -f "$MIGRATION_RUNNER" ]; then
    echo "entrypoint: $MIGRATION_RUNNER not found, skipping migrations"
    exec apache2-foreground
fi

if [ ! -f "$LOCAL_XML" ]; then
    echo "entrypoint: $LOCAL_XML not found, skipping migrations"
    exec apache2-foreground
fi

# Clear Magento runtime cache so template/config/layout changes in this
# deploy are picked up on first request. Dockerfile clears at build time,
# but Coolify volume mounts can shadow that; this guarantees freshness.
# Preserves var/session (users stay logged in) and var/log (debug history).
echo "entrypoint: clearing Magento runtime cache..."
rm -rf /var/www/html/var/cache/* \
       /var/www/html/var/full_page_cache/* \
       /var/www/html/var/tmp/* \
       /var/www/html/var/locks/* 2>/dev/null || true

echo "entrypoint: running migrations..."

MAX_ATTEMPTS=12
SLEEP=5

for i in $(seq 1 $MAX_ATTEMPTS); do
    if php "$MIGRATION_RUNNER"; then
        echo "entrypoint: migrations complete"
        break
    fi
    if [ "$i" -eq "$MAX_ATTEMPTS" ]; then
        echo "entrypoint: migrations failed after $MAX_ATTEMPTS attempts, aborting"
        exit 1
    fi
    echo "entrypoint: migration attempt $i failed, retrying in ${SLEEP}s..."
    sleep $SLEEP
done

exec apache2-foreground
