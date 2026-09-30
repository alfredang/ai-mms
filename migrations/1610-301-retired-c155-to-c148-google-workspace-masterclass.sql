-- Retired C155 (Google Workspace with Gemini, disabled in 1609) -> 301 to
-- C148 Google Workspace Masterclass (/google-workspace-masterclass.html).
--
-- 1. Repoint the manual 301s that chained INTO the retired slug (old slugs such
--    as ai-applications-to-google-workspace.html) straight at C148, flat target.
-- 2. Replace the retired product's own SYSTEM rows (flat + category-prefixed
--    paths) with manual 301 rows under their own id_path - a system row updated
--    in place gets reclaimed by the next Catalog URL Rewrites reindex.
-- 3. Move C155's url_key to a -retired slug so the reindex (which does not skip
--    disabled products) regenerates its rows there instead of fighting for the
--    redirected paths.
-- SG only; idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C155' LIMIT 1);

-- 1. Chained 301s -> C148
UPDATE core_url_rewrite
SET target_path = 'google-workspace-masterclass.html', options = 'RP', is_system = 0,
    product_id = NULL, category_id = NULL
WHERE @sg = 1 AND is_system = 0
  AND (target_path = 'google-workspace-with-gemini.html'
       OR target_path LIKE '%/google-workspace-with-gemini.html');

-- 2. Retired slug's own paths -> C148
DROP TEMPORARY TABLE IF EXISTS tmp_c155_paths;
CREATE TEMPORARY TABLE tmp_c155_paths (request_path VARCHAR(255) NOT NULL PRIMARY KEY);

INSERT IGNORE INTO tmp_c155_paths (request_path)
SELECT request_path FROM core_url_rewrite
WHERE @sg = 1 AND (request_path = 'google-workspace-with-gemini.html'
                   OR request_path LIKE '%/google-workspace-with-gemini.html');

INSERT IGNORE INTO tmp_c155_paths (request_path)
SELECT 'google-workspace-with-gemini.html' FROM DUAL WHERE @sg = 1;

DELETE FROM core_url_rewrite
WHERE @sg = 1 AND is_system = 1
  AND (request_path = 'google-workspace-with-gemini.html'
       OR request_path LIKE '%/google-workspace-with-gemini.html');

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id,
       CONCAT('manual-301-', MD5(t.request_path), '-', s.store_id),
       t.request_path, 'google-workspace-masterclass.html', 0, 'RP',
       'C155 retired -> C148 Google Workspace Masterclass'
FROM tmp_c155_paths t
CROSS JOIN (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1
ON DUPLICATE KEY UPDATE target_path = VALUES(target_path), options = 'RP', is_system = 0,
                        product_id = NULL, category_id = NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_c155_paths;

-- 3. Park the retired product's url_key
UPDATE catalog_product_entity_varchar
SET value = 'google-workspace-with-gemini-retired'
WHERE @sg = 1 AND entity_id = @pid AND value = 'google-workspace-with-gemini'
  AND attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
