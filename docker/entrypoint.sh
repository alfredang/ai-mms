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
