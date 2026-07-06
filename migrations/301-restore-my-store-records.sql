-- 301-restore-my-store-records.sql
--
-- Migration 300 detected the MY instance by checking for sales_flat_order
-- rows with store_id=2. On the MY instance, orders appear to be stamped
-- store_id=1 (single-store default), so that detection silently skipped MY.
-- Migration 300 is already applied and won't re-run.
--
-- This migration uses a more reliable three-condition fingerprint:
--   1. core_store has no store_id=2 row (migration 205 deleted it on all instances)
--   2. catalog_product_entity has M% SKUs (only MY / GH / NG instances do;
--      SG uses C% and TGS-% only)
--   3. core_store has no store_id=3 row (GH now has store_id=3 restored by
--      migration 300, so this exclusion skips the GH instance)
--
-- Together these three conditions fire only on the MY instance.
-- Idempotent: INSERT IGNORE / ON DUPLICATE KEY UPDATE throughout.

SET @my_store_missing = (
    SELECT IF(COUNT(*) = 0, 1, 0) FROM core_store WHERE store_id = 2
);
SET @has_m_skus = (
    SELECT IF(COUNT(*) > 0, 1, 0) FROM catalog_product_entity WHERE sku LIKE 'M%' LIMIT 1
);
-- After migration 300, GH has store_id=3 restored; MY never had one.
SET @not_gh_instance = (
    SELECT IF(COUNT(*) = 0, 1, 0) FROM core_store WHERE store_id = 3
);
SET @do_my = (@my_store_missing = 1 AND @has_m_skus = 1 AND @not_gh_instance = 1);

SET @sql = IF(@do_my,
    'INSERT IGNORE INTO core_website (website_id, code, name, sort_order, default_group_id, is_default) VALUES (2, ''malaysia'', ''Malaysia'', 2, 2, 0)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_my,
    'INSERT IGNORE INTO core_store_group (group_id, website_id, name, root_category_id, default_store_id) VALUES (2, 2, ''Malaysia'', 2, 2)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_my,
    'INSERT IGNORE INTO core_store (store_id, code, website_id, group_id, name, sort_order, is_active) VALUES (2, ''malaysia'', 2, 2, ''Malaysia Store View'', 0, 1)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_my,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''websites'', 2, ''web/unsecure/base_url'', ''https://www.tertiarycourses.com.my/'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_my,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''websites'', 2, ''web/secure/base_url'', ''https://www.tertiarycourses.com.my/'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_my,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''stores'', 2, ''web/unsecure/base_url'', ''https://www.tertiarycourses.com.my/'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_my,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''stores'', 2, ''web/secure/base_url'', ''https://www.tertiarycourses.com.my/'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_my,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''websites'', 2, ''currency/options/base'', ''MYR'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_my,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''websites'', 2, ''currency/options/default'', ''MYR'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_my,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''websites'', 2, ''currency/options/allow'', ''MYR'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_my,
    'INSERT IGNORE INTO catalog_product_website (product_id, website_id) SELECT e.entity_id, 2 FROM catalog_product_entity e WHERE e.sku LIKE ''M%'' OR e.sku LIKE ''TGS-%''',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
