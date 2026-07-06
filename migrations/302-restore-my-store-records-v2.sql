-- 302-restore-my-store-records-v2.sql
--
-- Migrations 300 and 301 both failed to restore the MY instance because:
--   - Migration 300 detected MY by looking for sales_flat_order.store_id=2,
--     but MY's orders are all stamped store_id=1 (single-store default).
--   - Migration 301 detected MY by looking for M% SKUs, but MY's catalog
--     is cloned from SG and contains only C% / TGS-% SKUs.
--
-- After migration 300 ran on all instances:
--   SG: store_id=2 (malaysia) AND store_id=3 (ghana) were BOTH added to
--       core_store, because SG's DB contains historical orders for both
--       store_ids from the old multi-store era.
--   GH: store_id=3 (ghana) was restored; store_id=2 may or may not be
--       present depending on whether GH had any store_id=2 orders.
--   MY: NEITHER store_id=2 nor store_id=3 was restored, because MY had
--       no orders stamped with those store_ids.
--
-- Reliable MY fingerprint (post-migration-300):
--   1. core_store has no store_id=2 row  (MY's own store, still missing)
--   2. core_store has no store_id=3 row  (GH store — present on SG and GH
--      after migration 300, absent on MY which never had store_id=3 orders)
--   3. sales_flat_order has at least one row  (it's a real live instance)
--
-- Together these three conditions fire only on the MY instance.
-- Idempotent: INSERT IGNORE / ON DUPLICATE KEY UPDATE throughout.

SET @my_store_missing = (
    SELECT IF(COUNT(*) = 0, 1, 0) FROM core_store WHERE store_id = 2
);
-- After migration 300, SG and GH both have store_id=3 in core_store.
-- Only MY still has it absent.
SET @gh_store_missing = (
    SELECT IF(COUNT(*) = 0, 1, 0) FROM core_store WHERE store_id = 3
);
SET @has_orders = (
    SELECT IF(COUNT(*) > 0, 1, 0) FROM sales_flat_order LIMIT 1
);
SET @do_my = (@my_store_missing = 1 AND @gh_store_missing = 1 AND @has_orders = 1);

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
    'INSERT IGNORE INTO catalog_product_website (product_id, website_id) SELECT e.entity_id, 2 FROM catalog_product_entity e',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
