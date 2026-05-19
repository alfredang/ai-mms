#!/usr/bin/env bash
set -euo pipefail

# Switch Magento base URL behavior to LIVE-DOMAIN mode (prod-like URLs).
#
# Usage:
#   bash scripts/local-dev/set-redirect-mode-live.sh
#
# Optional env overrides:
#   DB_CONTAINER=ai-mms-db_mysql-1
#   WEB_CONTAINER=ai-mms-web-1

DB_CONTAINER="${DB_CONTAINER:-ai-mms-db_mysql-1}"
WEB_CONTAINER="${WEB_CONTAINER:-ai-mms-web-1}"

if [[ ! -f ".env" ]]; then
  echo "ERROR: .env not found in repo root."
  exit 1
fi

# shellcheck disable=SC1091
source .env

: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required in .env}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required in .env}"

echo "Switching redirect mode to LIVE domains ..."

for f in \
  migrations/075-set-singapore-store-base-url.sql \
  migrations/081-restore-country-store-base-urls.sql \
  migrations/083-restore-infotech-base-url.sql
do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: missing migration file: $f"
    exit 1
  fi
  echo "Applying $f"
  docker exec -i "$DB_CONTAINER" mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < "$f"
done

docker exec -i "$DB_CONTAINER" mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" <<'SQL'
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
('default',0,'web/unsecure/base_url','https://www.tertiarycourses.com.sg/'),
('default',0,'web/secure/base_url','https://www.tertiarycourses.com.sg/'),
('default',0,'web/unsecure/base_link_url','{{unsecure_base_url}}'),
('default',0,'web/secure/base_link_url','{{secure_base_url}}'),
('default',0,'web/url/redirect_to_base','1'),
('default',0,'web/secure/use_in_frontend','1'),
('default',0,'web/secure/use_in_adminhtml','1')
ON DUPLICATE KEY UPDATE value=VALUES(value);
SQL

docker exec -i "$WEB_CONTAINER" bash -lc 'rm -rf /var/www/html/var/cache/*'

echo "Done. Redirect mode is now LIVE-domain mode."
echo "Example frontend domains:"
echo "  https://www.tertiarycourses.com.sg/"
echo "  https://www.tertiarycourses.com.my/"
echo "  https://www.tertiarycourses.com.gh/"
echo "  https://www.tertiarycourses.com.ng/"
echo "  https://www.tertiaryinfotech.edu.sg/"
