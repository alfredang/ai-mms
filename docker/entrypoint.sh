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

# Defensive: re-enable the Apache modules referenced by .htaccess on every
# container start. The Dockerfile already runs a2enmod, but certain restart
# paths (image rebuilds without cache, volume-shadowed /etc/apache2 from
# Coolify) have dropped them at runtime — without mod_headers the .htaccess
# "Header" directive 500s every request. a2enmod is idempotent, so this is
# a cheap safety net that costs nothing on a healthy container.
a2enmod headers expires brotli rewrite deflate >/dev/null 2>&1 || true

# Mirror the `claude` CLI credentials from /root/.claude (mounted from the
# host) into /var/www/.claude so Apache (running as www-data, HOME=/var/www)
# can find them. /root is 0700 root-only so www-data can't read it directly;
# without this copy, server-side claude calls (admin Course Edit > "Generate
# SEO Meta with AI") hang at the auth prompt until our PHP timeout fires,
# silently falling back to the deterministic stub.
#
# We RE-SYNC on every container start (not just first-boot) because the host's
# OAuth token rotates periodically — if we keep the original copy, it goes stale
# and `claude -p` returns 401 → SEO falls back to stub forever until someone
# manually re-copies. Resyncing on each `docker-compose up/restart` is the
# cheapest way to keep auth fresh.
if [ -d /root/.claude ]; then
    rm -rf /var/www/.claude 2>/dev/null
    cp -r /root/.claude /var/www/.claude 2>/dev/null \
        && chown -R www-data:www-data /var/www/.claude \
        && chmod 700 /var/www/.claude \
        && chmod 600 /var/www/.claude/.credentials.json 2>/dev/null \
        && echo "entrypoint: re-synced ~/.claude credentials to /var/www/ for Apache"
fi
if [ -f /root/.claude.json ]; then
    cp /root/.claude.json /var/www/.claude.json 2>/dev/null \
        && chown www-data:www-data /var/www/.claude.json \
        && chmod 600 /var/www/.claude.json
fi

if [ ! -f "$MIGRATION_RUNNER" ]; then
    echo "entrypoint: $MIGRATION_RUNNER not found, skipping migrations"
    exec apache2-foreground
fi

# Country mode boot sequence:
#   1. Re-enable Cm_RedisSession — the Dockerfile sed disables it for SG (which
#      has no Redis service); country instances bundle their own Redis (P7).
#   2. Regenerate local.xml from env — the image's baked-in local.xml is
#      SG-specific (host=db_mysql, no Redis blocks). Country instances always
#      generate a fresh one pointing at 'db' with Redis session+cache blocks.
if [ "${MMS_MODE:-}" = "country" ]; then
    sed -i 's|<active>false</active>|<active>true</active>|' \
        /var/www/html/app/etc/modules/Cm_RedisSession.xml 2>/dev/null || true
    echo "entrypoint: Cm_RedisSession re-enabled for MMS_MODE=country"

    rm -f "$LOCAL_XML" 2>/dev/null || true
    bash /var/www/html/docker/generate-local-xml.sh \
        || { echo "entrypoint: FATAL — generate-local-xml.sh failed"; exit 1; }
fi

if [ ! -f "$LOCAL_XML" ]; then
    echo "entrypoint: $LOCAL_XML not found, skipping migrations"
    exec apache2-foreground
fi

# Inject Redis object-cache block into local.xml for non-country instances (SG prod).
# Activate by setting REDIS_HOST=redis in Coolify env + adding a redis service.
# Country instances (MMS_MODE=country) get Redis via generate-local-xml.sh above.
# Sessions stay on MySQL — Cm_RedisSession stays disabled (vendor incompatibility).
if [ -n "${REDIS_HOST:-}" ] && [ "${MMS_MODE:-}" != "country" ]; then
    php /var/www/html/docker/patch-redis-in-local-xml.php \
        || echo "entrypoint: WARNING — Redis cache local.xml patch failed (non-fatal)"
fi

apply_local_db_mode() {
    if [ "${LOCAL_DB_MODE:-0}" = "1" ]; then
        echo "entrypoint: LOCAL_DB_MODE=1 — applying local dev URL overrides..."
        php /var/www/html/scripts/local-dev/apply-local-dev-urls.php \
            || echo "entrypoint: WARNING — local dev URL override failed (non-fatal)"
    fi
}

if [ "${SKIP_MIGRATIONS:-0}" = "1" ]; then
    echo "entrypoint: SKIP_MIGRATIONS=1, skipping migrations"
    apply_local_db_mode
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

# If Redis is configured as the cache backend (local dev via docker-compose),
# flush its DBs too — otherwise stale entries from the previous container
# survive the cache wipe above and template/config/layout changes don't show.
# Non-fatal: missing Redis or missing redis-cli simply skips the flush.
# Reads host/port from app/etc/local.xml so prod (no <cache> block) is a no-op.
if grep -q "Cm_Cache_Backend_Redis" /var/www/html/app/etc/local.xml 2>/dev/null; then
    REDIS_HOST=$(awk -F'[<>]' '/<server>/{print $3; exit}' /var/www/html/app/etc/local.xml 2>/dev/null)
    REDIS_HOST=${REDIS_HOST:-redis}
    if command -v redis-cli >/dev/null 2>&1; then
        redis-cli -h "$REDIS_HOST" -n 0 FLUSHDB >/dev/null 2>&1 \
            && echo "entrypoint: flushed Redis cache db 0 on $REDIS_HOST"
    else
        # Pure-PHP flush via Credis (always available in vendor) so we don't
        # need redis-cli in the image just for this.
        php -r "
            require '/var/www/html/vendor/autoload.php';
            try {
                \$c = new Credis_Client('$REDIS_HOST', 6379, 2);
                \$c->select(0); \$c->flushDb();
                echo \"entrypoint: flushed Redis cache db 0 on $REDIS_HOST (via Credis)\n\";
            } catch (Throwable \$e) {
                echo \"entrypoint: Redis flush skipped — \" . \$e->getMessage() . \"\n\";
            }
        " 2>/dev/null || true
    fi
fi

# Guarantee the merge-bundle directories exist AND are writable by Apache.
# Required because:
#   - .dockerignore excludes the whole `media/` tree from the image, so a
#     fresh Coolify volume can start without any of these subdirs.
#   - Even when they exist on the volume, Coolify sometimes mounts them
#     owned by root, which makes Magento's first-request bundle write fail
#     silently — admin pages then load with NO styles (the merge URL 404s).
# Idempotent on healthy volumes; fixes broken ones.
mkdir -p /var/www/html/media/css /var/www/html/media/css_secure /var/www/html/media/js
chown -R www-data:www-data /var/www/html/media/css /var/www/html/media/css_secure /var/www/html/media/js
chmod -R u+rwX,g+rwX /var/www/html/media/css /var/www/html/media/css_secure /var/www/html/media/js

# Admin My Profile avatar uploads land in media/admin/profile/ via
# MMD_Adminhtml_System_AccountController. On a fresh container the
# directory doesn't exist (media/ is .dockerignored), so the first
# upload would fail with "Destination folder is not writable or
# does not exist." Pre-create with www-data ownership so the very
# first Save Changes click already works.
mkdir -p /var/www/html/media/admin/profile
chown -R www-data:www-data /var/www/html/media/admin
chmod -R u+rwX,g+rwX /var/www/html/media/admin

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

# Seed WYSIWYG assets referenced by CMS / product descriptions (e.g. the
# HRD Corp Claimable logo on Malaysia course pages). The media/ tree is a
# Coolify-mounted volume, so the build-time COPY can't reach it. Use a
# COPY-IF-MISSING policy — never overwrite, because admins upload arbitrary
# wysiwyg files via the CMS and we must not clobber them.
WYS_SEED_DIR=/var/www/html/docker/seeds/wysiwyg
WYS_TARGET_DIR=/var/www/html/media/wysiwyg
if [ -d "$WYS_SEED_DIR" ]; then
    mkdir -p "$WYS_TARGET_DIR"
    # find -type f handles nested seed paths (e.g. infortis/ultimo/custom/*).
    # Relative path is preserved on the target side.
    while IFS= read -r f; do
        rel="${f#$WYS_SEED_DIR/}"
        target="$WYS_TARGET_DIR/$rel"
        if [ ! -f "$target" ]; then
            mkdir -p "$(dirname "$target")"
            cp "$f" "$target" && echo "entrypoint: seeded $target"
        fi
    done < <(find "$WYS_SEED_DIR" -type f)
    chown -R www-data:www-data "$WYS_TARGET_DIR" 2>/dev/null || true
    chmod -R a+r "$WYS_TARGET_DIR" 2>/dev/null || true
fi

# Seed catalog product gallery images (media/catalog/product/<h>/<a>/<file>)
# so migrations that attach images via catalog_product_entity_media_gallery
# have something to point at on the volume-mounted media disk. Same
# COPY-IF-MISSING contract as the wysiwyg seed: never overwrite admin uploads.
CPG_SEED_DIR=/var/www/html/docker/seeds/catalog_product
CPG_TARGET_DIR=/var/www/html/media/catalog/product
if [ -d "$CPG_SEED_DIR" ]; then
    mkdir -p "$CPG_TARGET_DIR"
    while IFS= read -r f; do
        rel="${f#$CPG_SEED_DIR/}"
        target="$CPG_TARGET_DIR/$rel"
        if [ ! -f "$target" ]; then
            mkdir -p "$(dirname "$target")"
            cp "$f" "$target" && echo "entrypoint: seeded $target"
        fi
    done < <(find "$CPG_SEED_DIR" -type f)
    chown -R www-data:www-data "$CPG_TARGET_DIR" 2>/dev/null || true
    chmod -R a+r "$CPG_TARGET_DIR" 2>/dev/null || true
fi

echo "entrypoint: running migrations..."

MAX_ATTEMPTS=12
SLEEP=5

for i in $(seq 1 $MAX_ATTEMPTS); do
    if php "$MIGRATION_RUNNER"; then
        echo "entrypoint: migrations complete"
        apply_local_db_mode
        # Sync SMTPPro fallback passwords from env -> core_config_data
        # (encrypted). No-op if the relevant env vars are unset. Never fatal:
        # SMTP misconfig should not block the container from serving traffic.
        php /var/www/html/scripts/maintenance/ensure-smtp-fallback-passwords.php \
            || echo "entrypoint: WARNING — SMTP fallback sync errored (non-fatal)"
        break
    fi
    if [ "$i" -eq "$MAX_ATTEMPTS" ]; then
        echo "entrypoint: migrations failed after $MAX_ATTEMPTS attempts, aborting"
        exit 1
    fi
    echo "entrypoint: migration attempt $i failed, retrying in ${SLEEP}s..."
    sleep $SLEEP
done

# Sync SG_SYNC_API_KEY from env → core_config_data['mmd/course_sync/api_key'].
# On SG: the key the ExportController validates on incoming requests.
# On country instances: the key CourseSyncService sends as X-API-Key.
# Both sides use the same config path. No-op if env var is unset.
if [ -n "${SG_SYNC_API_KEY:-}" ]; then
    php -r "
        require '/var/www/html/app/Mage.php';
        Mage::app('admin');
        Mage::getModel('core/config')->saveConfig(
            'mmd/course_sync/api_key', getenv('SG_SYNC_API_KEY'), 'default', 0
        );
        echo 'ok';
    " 2>/dev/null | grep -q ok \
        && echo "entrypoint: SG_SYNC_API_KEY written to core_config_data" \
        || echo "entrypoint: WARNING — SG_SYNC_API_KEY sync failed (non-fatal)"
fi

# Country instances: write MMS_BASE_URL into core_config_data so Magento
# generates correct links for the current URL (IP during setup, domain after
# DNS). Runs every boot so changing MMS_BASE_URL in Coolify + redeploy is
# enough to update the URLs — no manual DB edit needed.
if [ "${MMS_MODE:-}" = "country" ] && [ -n "${MMS_BASE_URL:-}" ] && [ -n "${MMS_COUNTRY_CODE:-}" ]; then
    php -r "
        require '/var/www/html/app/Mage.php';
        Mage::app('admin');
        \$url  = rtrim(getenv('MMS_BASE_URL'), '/') . '/';
        \$ccMap = ['MY'=>'malaysia', 'GH'=>'ghana', 'NG'=>'nigeria', 'BT'=>'bhutan', 'IN'=>'india'];
        \$cc   = strtoupper(getenv('MMS_COUNTRY_CODE'));
        \$code = \$ccMap[\$cc] ?? '';
        if (!\$code) { echo 'skip'; exit; }
        \$website = Mage::getModel('core/website')->load(\$code, 'code');
        if (!\$website->getId()) { echo 'skip'; exit; }
        \$wid  = (int)\$website->getId();
        \$sid  = (int)\$website->getDefaultStore()->getId();
        \$cfg  = Mage::getModel('core/config');
        \$cfg->saveConfig('web/unsecure/base_url', \$url, 'default', 0);
        \$cfg->saveConfig('web/secure/base_url',   \$url, 'default', 0);
        \$cfg->saveConfig('web/unsecure/base_url', \$url, 'websites', \$wid);
        \$cfg->saveConfig('web/secure/base_url',   \$url, 'websites', \$wid);
        if (\$sid) {
            \$cfg->saveConfig('web/unsecure/base_url', \$url, 'stores', \$sid);
            \$cfg->saveConfig('web/secure/base_url',   \$url, 'stores', \$sid);
        }
        echo 'ok';
    " 2>/dev/null | grep -q ok \
        && echo "entrypoint: base URL set to ${MMS_BASE_URL}/ for ${MMS_COUNTRY_CODE}" \
        || echo "entrypoint: WARNING — base URL update failed (non-fatal)"
fi

# Generate active Google Sitemap XML files immediately after migrations. The
# sitemap table is DB-managed, while media/root XML files are runtime artifacts
# on the Coolify volume; without this, /sitemap.xml can 404 until cron runs.
if [ -f /var/www/html/scripts/seo/generate-sitemaps.php ]; then
    echo "entrypoint: generating active sitemap XML files..."
    php /var/www/html/scripts/seo/generate-sitemaps.php \
        || echo "entrypoint: WARNING — sitemap generation failed (non-fatal)"
    chown www-data:www-data /var/www/html/sitemap_*.xml 2>/dev/null || true
    chmod a+r /var/www/html/sitemap_*.xml 2>/dev/null || true
fi

# One-shot reindex: catalog_url + catalog_category_flat. Required after the
# MMD_FlatCategoryUrl module shipped — module changes the URL builder but
# does NOT itself rewrite existing core_url_rewrite rows or category url_path
# attributes; only a reindex does that. Admin's Index Management page can't
# bulk-reindex (Varien mass-action doesn't actually fire on index_process),
# so trigger it here, once per volume. Sentinel lives on the Coolify volume
# at var/.reindexed-flat-urls — delete the file to force a re-run on next
# boot (e.g. after a category-tree change that needs URL regeneration).
# Flat-URL reindex. Marker is INTENTIONALLY ignored for now because prod's
# first-run marker may have been created by a botched reindex (module not
# loaded yet / stale config cache) — re-runs are cheap (~60s) and produce
# the only correct output we have. Reinstate the marker gate once prod is
# stable and verified flat.
echo "entrypoint: reindexing catalog_url + catalog_category_flat (MMD_FlatCategoryUrl)..."
su -s /bin/sh www-data -c "php /var/www/html/shell/indexer.php --reindex catalog_url,catalog_category_flat" 2>&1 \
    && echo "entrypoint: flat-URL reindex complete" \
    || echo "entrypoint: WARNING — flat-URL reindex failed (non-fatal, container continues)"

# Force-flatten every category URL using MMD_FlatCategoryUrl directly. This
# runs INDEPENDENT of the catalog_url indexer because on prod the indexer
# silently produced deep paths (OPcache + autoload race during the very first
# reindex post-deploy meant our class fell back to stock Mage_Catalog_Model_Url).
# Script is idempotent — on a flat DB it skips every category. Gated by a
# sentinel so we don't pay the ~30s scan on every restart; delete the file
# to force a re-run.
# One-shot cleanup of unused media folders (dhl, downloadable, providers,
# trainers, infortis, MagentoCaptcha, xmlconnect). Idempotent — skips
# missing folders, gated by var/.cleaned-unused-media-2026-06-02 sentinel.
# bankpayment is NOT touched (customer payment proofs).
bash /var/www/html/scripts/maintenance/cleanup-unused-media.sh \
    || echo "entrypoint: WARNING — unused-media cleanup errored (non-fatal)"

# Fix the -1 collision suffix bug introduced by the first force-flatten run.
# Runs on every boot until manually disabled — idempotent (no-op on clean DB).
echo "entrypoint: fixing -N collision suffix on category canonical rewrites..."
php /var/www/html/scripts/maintenance/fix-collision-suffix.php \
    || echo "entrypoint: WARNING — collision-suffix fix errored (non-fatal)"

FLATTEN_MARKER=/var/www/html/var/.force-flattened-category-urls
if [ ! -f "$FLATTEN_MARKER" ]; then
    echo "entrypoint: force-flatten category URLs (one-shot)..."
    if php /var/www/html/scripts/maintenance/force-flatten-category-urls.php; then
        touch "$FLATTEN_MARKER"
        chown www-data:www-data "$FLATTEN_MARKER"
        echo "entrypoint: force-flatten complete"
    else
        echo "entrypoint: WARNING — force-flatten failed (non-fatal, container continues)"
    fi
fi

# Always run the flat-URL diagnostic dumper so /media/flat-url-debug.json is
# fresh on every boot. Public read; reports module-active, runtime URL class,
# rewrite rows + url_path for category 196. Lets us debug remote prod state
# without shell access.
php /var/www/html/scripts/maintenance/flat-url-debug.php \
    || echo "entrypoint: WARNING — flat-URL diagnostic dump failed (non-fatal)"

# Warm the merged CSS/JS bundles BEFORE real traffic arrives. The cache wipe
# at line ~85 deletes media/css/*, media/js/* on every container start;
# Magento regenerates them on the FIRST request that loads the layout. If a
# real admin/storefront request lands during that ~200ms window, the HTML
# references the merge URL but the file does not yet exist → 404 → page
# loads with no styles ("distorted, refresh fixes it" — documented in
# CLAUDE.md). Workaround: background-warm with curl after Apache starts.
# Touches both /tigerdragon (admin) and / (storefront) so both bundles
# materialise. All errors silenced — warm-up is best-effort, never fatal.
(
    for _w in 1 2 3 4 5 6 7 8 9 10; do
        if curl -s -o /dev/null --max-time 2 http://127.0.0.1/ 2>/dev/null; then
            break
        fi
        sleep 1
    done
    curl -s -o /dev/null --max-time 15 -L http://127.0.0.1/ 2>/dev/null || true
    curl -s -o /dev/null --max-time 15 -L http://127.0.0.1/tigerdragon/ 2>/dev/null || true
    echo "entrypoint: CSS/JS merge bundles warmed"
) &

exec apache2-foreground
