#!/usr/bin/env bash
# Franchise parity — connection helpers. `source scripts/lib.sh` then use gq/gsql/reindex_flush/sgq/r2.
# Set these per partner (creds live in the repo .env; NEVER commit them here):
: "${SSHPASS:?export SSHPASS=<partner root pw from .env>}"
PARTNER_HOST="${PARTNER_HOST:-root@<partner-ip>}"        # GH example
PARTNER_DB="${PARTNER_DB:?export PARTNER_DB=<mysql container, docker ps|grep mysql:5.7>}"
PARTNER_WEB="${PARTNER_WEB:?export PARTNER_WEB=<web container>}"
PARTNER_DBNAME="${PARTNER_DBNAME:-mms_gh}"              # docker exec $DB sh -c 'echo $MYSQL_DATABASE'
SG_LOCAL_DB="${SG_LOCAL_DB:-ai-mms-db_mysql-1}"; SG_LOCAL_DBNAME="${SG_LOCAL_DBNAME:-courses_backupDB}"
R2_PUBLIC="${R2_PUBLIC:-https://pub-77c0dec029944b0386e40673ce81081f.r2.dev}"
SSH="sshpass -e ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 $PARTNER_HOST"

# Query the partner DB (read). $1 = SQL (use single quotes carefully; prefer gsql for complex SQL).
gq(){ $SSH "docker exec $PARTNER_DB sh -c 'mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" $PARTNER_DBNAME -N -e \"$1\"'" 2>&1 | grep -v Warning; }
# Apply a SQL FILE to the partner DB via stdin (dodges all quote hell — ALWAYS prefer this for writes).
gsql(){ $SSH "docker exec -i $PARTNER_DB sh -c 'mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" $PARTNER_DBNAME'" < "$1" 2>&1 | grep -vi warning; }
# Reindex flat/product/url + flush Redis (run as its own step; can exceed 2 min).
reindex_flush(){ $SSH "docker exec $PARTNER_WEB php -r '
  require \"/var/www/html/app/Mage.php\"; Mage::app();
  foreach([\"catalog_category_flat\",\"catalog_category_product\",\"catalog_url\"] as \$c){
    \$p=Mage::getModel(\"index/indexer\")->getProcessByCode(\$c); if(\$p){\$p->reindexEverything(); echo \$c.\" ok\n\";}}
  Mage::app()->getCacheInstance()->flush(); echo \"flushed\n\";'" 2>&1 | tail -5; }
flush_only(){ $SSH "docker exec $PARTNER_WEB php -r 'require \"/var/www/html/app/Mage.php\"; Mage::app(); Mage::app()->getCacheInstance()->flush(); echo \"flushed\";'" 2>&1 | tail -1; }
# Read the SG reference (LOCAL BACKUP — read-only, never touches SG prod). $1 = SQL.
sgq(){ docker exec "$SG_LOCAL_DB" sh -c "mysql -umagento -pmagento123 $SG_LOCAL_DBNAME -N -e \"$1\"" 2>&1 | grep -v Warning; }
# Upload a file to R2 (needs R2_* in env). $1 = local file, $2 = key (e.g. wysiwyg/x.jpg).
r2(){ source <(grep -E '^R2_' .env | sed 's/^/export /'); rclone copyto "$1" ":s3:$R2_BUCKET/$2" \
  --s3-provider Cloudflare --s3-access-key-id "$R2_ACCESS_KEY_ID" --s3-secret-access-key "$R2_SECRET_ACCESS_KEY" \
  --s3-endpoint "$R2_ENDPOINT" --s3-no-check-bucket --header-upload "Content-Type: ${3:-image/jpeg}"; \
  echo "$R2_PUBLIC/$2 -> $(curl -s -o /dev/null -w '%{http_code}' "$R2_PUBLIC/$2")"; }
# Resolve a category EAV attribute id on the partner: attr_id <name>
attr_id(){ gq "SELECT attribute_id FROM eav_attribute WHERE attribute_code='$1' AND entity_type_id=3"; }
