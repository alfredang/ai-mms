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

if [ "${SKIP_MIGRATIONS:-0}" = "1" ]; then
    echo "entrypoint: SKIP_MIGRATIONS=1, skipping migrations"
    exec apache2-foreground
fi

# Clear Magento runtime cache so template/config/layout changes in this
# deploy are picked up on first request. Dockerfile clears at build time,
# but Coolify volume mounts can shadow that; this guarantees freshness.
# Preserves var/session (users stay logged in) and var/log (debug history).
#
# Also clear the MERGED CSS/JS bundles. dev/css/merge_css_files and
# dev/js/merge_files are ON in production, so the browser loads a cached
# media/css/<hash>.css — without deleting it here, skin/**/*.css|js
# changes shipped in a deploy stay invisible until the bundle happens to
# regenerate. media/ is Coolify-volume-mounted so the build-time COPY
# can't pre-clear it; do it at runtime. Magento rebuilds the bundle on
# the first request.
echo "entrypoint: clearing Magento runtime cache + merged CSS/JS..."
rm -rf /var/www/html/var/cache/* \
       /var/www/html/var/full_page_cache/* \
       /var/www/html/var/tmp/* \
       /var/www/html/var/locks/* \
       /var/www/html/media/css/* \
       /var/www/html/media/css_secure/* \
       /var/www/html/media/js/* 2>/dev/null || true

# Seed transactional-email logo into media/email/logo/default/.
# The `media/` directory is Coolify-volume-mounted in production, so baked
# COPY assets get shadowed — seed at runtime so the unified logo referenced
# by migration 068 is actually present on disk. Overwrite every boot so a
# stale or zero-byte file in the volume can't permanently break the email
# header logo (was: skip-if-exists, which left bad files in place).
SEED_DIR=/var/www/html/docker/seeds/email-logo
TARGET_DIR=/var/www/html/media/email/logo/default
if [ -d "$SEED_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    for f in "$SEED_DIR"/*; do
        [ -f "$f" ] || continue
        name=$(basename "$f")
        cp -f "$f" "$TARGET_DIR/$name" && echo "entrypoint: seeded $TARGET_DIR/$name"
    done
    chown -R www-data:www-data "$TARGET_DIR" 2>/dev/null || true
    chmod -R a+r "$TARGET_DIR" 2>/dev/null || true
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
