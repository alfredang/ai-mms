#!/usr/bin/env bash
set -euo pipefail

# Switch Magento base URL behavior to LOCALHOST mode for local development.
#
# Usage:
#   bash scripts/local-dev/set-redirect-mode-local.sh
#
# Optional env overrides:
#   DB_CONTAINER=ai-mms-db_mysql-1
#   WEB_CONTAINER=ai-mms-web-1
#   LOCAL_BASE_URL=http://localhost:8080/

DB_CONTAINER="${DB_CONTAINER:-ai-mms-db_mysql-1}"
WEB_CONTAINER="${WEB_CONTAINER:-ai-mms-web-1}"
LOCAL_BASE_URL="${LOCAL_BASE_URL:-http://localhost:8080/}"

if [[ ! -f ".env" ]]; then
  echo "ERROR: .env not found in repo root."
  exit 1
fi

# shellcheck disable=SC1091
source .env

: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required in .env}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required in .env}"

echo "Switching redirect mode to LOCAL ($LOCAL_BASE_URL) ..."

docker exec -i "$DB_CONTAINER" mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" <<SQL
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
('default',0,'web/unsecure/base_url','${LOCAL_BASE_URL}'),
('default',0,'web/secure/base_url','${LOCAL_BASE_URL}'),
('default',0,'web/unsecure/base_link_url','{{unsecure_base_url}}'),
('default',0,'web/secure/base_link_url','{{secure_base_url}}'),
('default',0,'web/unsecure/base_js_url','{{unsecure_base_url}}js/'),
('default',0,'web/secure/base_js_url','{{secure_base_url}}js/'),
('default',0,'web/unsecure/base_skin_url','{{unsecure_base_url}}skin/'),
('default',0,'web/secure/base_skin_url','{{secure_base_url}}skin/'),
('default',0,'web/unsecure/base_media_url','{{unsecure_base_url}}media/'),
('default',0,'web/secure/base_media_url','{{secure_base_url}}media/'),
('default',0,'web/secure/use_in_frontend','0'),
('default',0,'web/secure/use_in_adminhtml','0'),
('default',0,'web/url/redirect_to_base','0'),
('default',0,'web/cookie/cookie_domain','')
ON DUPLICATE KEY UPDATE value=VALUES(value);

DELETE FROM core_config_data
WHERE scope IN ('stores','websites')
  AND path IN (
    'web/unsecure/base_url','web/secure/base_url',
    'web/unsecure/base_link_url','web/secure/base_link_url',
    'web/unsecure/base_js_url','web/secure/base_js_url',
    'web/unsecure/base_skin_url','web/secure/base_skin_url',
    'web/unsecure/base_media_url','web/secure/base_media_url',
    'web/secure/use_in_frontend','web/secure/use_in_adminhtml',
    'web/url/redirect_to_base','web/cookie/cookie_domain'
  );
SQL

docker exec -i "$WEB_CONTAINER" bash -lc 'rm -rf /var/www/html/var/cache/*'

echo "Done. Redirect mode is now LOCAL."
echo "Open: ${LOCAL_BASE_URL}"
echo "Admin: ${LOCAL_BASE_URL}tigerdragon"
