-- 335-restore-gh-and-my-store-records.sql
--
-- Replaces migrations 300/301/302 which all used wrong instance detection:
--
--   300: detected GH by store_id=3 orders, MY by store_id=2 orders.
--        Both country instances stamp orders as store_id=1 (single-store
--        default), so both detections were silent no-ops on their target.
--        300 DID fire on SG (SG's old multi-store DB has orders for both
--        store_ids) and correctly added both store rows to SG's DB.
--
--   301: tried to detect MY by M% SKUs being present. But GH has M% SKUs
--        and MY does NOT (MY catalog is cloned from SG: C%/TGS-% only).
--        So 301 inserted store_id=2 (malaysia) into GH's DB instead of MY.
--        GH now has a spurious malaysia store and still has no ghana store.
--
-- Correct fingerprints (after migrations 300/301 have already run):
--
--   GH: catalog_product_entity has M% SKUs  (only GH courses use M prefix)
--       AND core_store has no store_id=3 row (ghana store still missing)
--
--   MY: catalog_product_entity has NO M% SKUs (MY = clone of SG catalog)
--       AND core_store has no store_id=2 row  (malaysia store still missing)
--       AND core_store has no store_id=3 row  (would be present on SG,
--           which had both restored by migration 300)
--       AND at least one order exists         (it's a real instance)
--
-- Cleanup: migration 301 accidentally inserted store_id=2 (malaysia) into
-- GH's DB. We remove it here before inserting the correct ghana rows.
--
-- Idempotent: INSERT IGNORE / ON DUPLICATE KEY UPDATE throughout.

-- -----------------------------------------------------------------------
-- GH: detect by M% SKUs + store_id=3 missing
-- -----------------------------------------------------------------------
SET @has_m_skus = (
    SELECT IF(COUNT(*) > 0, 1, 0) FROM catalog_product_entity WHERE sku LIKE 'M%' LIMIT 1
);
SET @gh_store_missing = (
    SELECT IF(COUNT(*) = 0, 1, 0) FROM core_store WHERE store_id = 3
);
SET @do_gh = (@has_m_skus = 1 AND @gh_store_missing = 1);

-- Clean up the spurious malaysia store that migration 301 wrongly inserted on GH
SET @sql = IF(@do_gh,
    'DELETE FROM core_store WHERE store_id = 2 AND code = ''malaysia''',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'DELETE FROM core_store_group WHERE group_id = 2',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF(@do_gh,
    'DELETE FROM core_website WHERE website_id = 2 AND code = ''malaysia''',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Insert correct ghana records
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
    'INSERT IGNORE INTO catalog_product_website (product_id, website_id) SELECT e.entity_id, 3 FROM catalog_product_entity e WHERE e.sku LIKE ''M%''',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- -----------------------------------------------------------------------
-- MY: detect by NO M% SKUs + store_id=2 missing + store_id=3 missing + has orders
-- -----------------------------------------------------------------------
SET @no_m_skus = (
    SELECT IF(COUNT(*) = 0, 1, 0) FROM catalog_product_entity WHERE sku LIKE 'M%' LIMIT 1
);
SET @my_store_missing = (
    SELECT IF(COUNT(*) = 0, 1, 0) FROM core_store WHERE store_id = 2
);
SET @gh_store_absent = (
    SELECT IF(COUNT(*) = 0, 1, 0) FROM core_store WHERE store_id = 3
);
SET @has_orders = (
    SELECT IF(COUNT(*) > 0, 1, 0) FROM sales_flat_order LIMIT 1
);
-- SG has both store_id=2 and store_id=3 (added by migration 300), so
-- my_store_missing=0 on SG. GH has M% SKUs so no_m_skus=0 on GH.
-- Only MY passes all four conditions.
SET @do_my = (@no_m_skus = 1 AND @my_store_missing = 1 AND @gh_store_absent = 1 AND @has_orders = 1);

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
