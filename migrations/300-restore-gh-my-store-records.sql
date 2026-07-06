-- 300-restore-gh-my-store-records.sql
--
-- Migration 205 ("Remove retired country stores") deleted core_store,
-- core_store_group, core_website, and core_config_data for store_ids 2
-- (Malaysia) and 3 (Ghana) from EVERY instance's DB, including the GH
-- and MY instances themselves. This broke GH and MY admin panels --
-- Magento can no longer route MAGE_RUN_CODE=ghana/malaysia because the
-- store records are gone, so it falls back to SG context and the course
-- manager / edit form break.
--
-- Detection: migration 205 explicitly kept historical sales records
-- (sales_flat_order rows were NOT deleted). We detect the GH instance
-- by checking for orders with store_id=3 that have no matching
-- core_store row; same logic for MY (store_id=2). On the SG instance,
-- store_id 2/3 were also deleted from core_store but there are no
-- orders stamped with those store_ids in SG's DB, so the guard fires
-- only on the right instances.
--
-- Idempotent: all inserts use INSERT IGNORE or ON DUPLICATE KEY UPDATE.

-- -----------------------------------------------------------------------
-- Ghana instance: restore store_id=3 if GH orders exist but store is gone
-- -----------------------------------------------------------------------
SET @gh_orders = (
    SELECT COUNT(*) FROM sales_flat_order WHERE store_id = 3 LIMIT 1
);
SET @gh_store_missing = (
    SELECT IF(COUNT(*) = 0, 1, 0) FROM core_store WHERE store_id = 3
);
SET @do_gh = (@gh_orders > 0 AND @gh_store_missing = 1);

SET @sql = IF(@do_gh,
    'INSERT IGNORE INTO core_website (website_id, code, name, sort_order, default_group_id, is_default) VALUES (3, ''ghana'', ''Ghana'', 3, 3, 0)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'INSERT IGNORE INTO core_store_group (group_id, website_id, name, root_category_id, default_store_id) VALUES (3, 3, ''Ghana'', 2, 3)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'INSERT IGNORE INTO core_store (store_id, code, website_id, group_id, name, sort_order, is_active) VALUES (3, ''ghana'', 3, 3, ''Ghana Store View'', 0, 1)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''websites'', 3, ''web/unsecure/base_url'', ''https://www.tertiarycourses.com.gh/'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''websites'', 3, ''web/secure/base_url'', ''https://www.tertiarycourses.com.gh/'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''stores'', 3, ''web/unsecure/base_url'', ''https://www.tertiarycourses.com.gh/'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''stores'', 3, ''web/secure/base_url'', ''https://www.tertiarycourses.com.gh/'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''websites'', 3, ''currency/options/base'', ''GHS'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''websites'', 3, ''currency/options/default'', ''GHS'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'INSERT INTO core_config_data (scope, scope_id, path, value) VALUES (''websites'', 3, ''currency/options/allow'', ''GHS'') ON DUPLICATE KEY UPDATE value = VALUES(value)',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'INSERT IGNORE INTO catalog_product_website (product_id, website_id) SELECT e.entity_id, 3 FROM catalog_product_entity e WHERE e.sku LIKE ''M%'' OR e.sku LIKE ''TGS-%''',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- -----------------------------------------------------------------------
-- Malaysia instance: restore store_id=2 if MY orders exist but store is gone
-- -----------------------------------------------------------------------
SET @my_orders = (
    SELECT COUNT(*) FROM sales_flat_order WHERE store_id = 2 LIMIT 1
);
SET @my_store_missing = (
    SELECT IF(COUNT(*) = 0, 1, 0) FROM core_store WHERE store_id = 2
);
SET @do_my = (@my_orders > 0 AND @my_store_missing = 1);

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
