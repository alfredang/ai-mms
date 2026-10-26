-- 1869: 301 the retired C1164 slug (and its legacy aliases) to C177.
--
-- WHY: GSC "Page with redirect" validation FAILED (2026-10-17). The 1,000-row
-- export was crawled on 2026-10-26: 998 were single 301s to a live page (benign,
-- re-validate only) and 2 were 301 -> 404. Both ended on
-- multi-ai-agents-system-for-algorithmic-trading.html, the slug of C1164
-- "Multi AI Agents System for Algorithmic Trading", which 1853 disabled without a
-- 301. Prod holds 6 legacy RP rows pointing at that slug (wiley deep-learning,
-- machine-learning-for-algorithmic-trading, multi-agents-system-..., ...).
-- Successor: C177 "Build a Multi AI Agents Workflow for Stock Trading" (1855),
-- the same multi-agent trading workflow; target curl-verified 0 redirects / 200.
--
-- HOW (the 1796 retire pattern):
--   1. C1164 url_key -> '<slug>-retired' so a catalog_url reindex never takes the
--      slug back for the disabled product;
--   2. the system row on the slug is replaced by a manual 301 (id_path gsc404-<md5>);
--   3. legacy RP rows and search redirects that pointed at the slug go straight to
--      C177 (no 2-hop), with product_id/category_id NULLed so the reindex keeps them
--      (memory feedback_catalog_url_reindex_deletes_rp_rows_tagged_with_dropped_membership).
-- SG only (@mms_instance + store guard) -> no-op on MY/GH. Idempotent.

SET @ok := (@mms_instance = 'SG' AND (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);

SET @src  := 'multi-ai-agents-system-for-algorithmic-trading.html';
SET @dst  := 'build-a-multi-ai-agents-workflow-for-stock-trading.html';
SET @key  := 'multi-ai-agents-system-for-algorithmic-trading';
SET @pid  := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1164' LIMIT 1);
SET @p_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @p_up := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');

-- 1. Release the slug from the disabled product.
UPDATE catalog_product_entity_varchar SET value = CONCAT(@key, '-retired')
 WHERE @ok AND entity_id = @pid AND attribute_id = @p_uk AND value = @key;
UPDATE catalog_product_entity_varchar SET value = CONCAT(@key, '-retired.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @p_up AND value = CONCAT(@key, '.html');

-- 2. Replace the row on the dead slug with a manual 301.
DELETE FROM core_url_rewrite
 WHERE @ok AND store_id IN (0, 1) AND request_path = @src AND id_path <> CONCAT('gsc404-', MD5(@src));

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, CONCAT('gsc404-', MD5(@src)), @src, @dst, 0, 'RP' FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = @src AND x.store_id = 1);

-- 3. Flatten the legacy aliases and search redirects that landed on the dead slug.
UPDATE core_url_rewrite
   SET target_path = @dst, product_id = NULL, category_id = NULL
 WHERE @ok AND store_id IN (0, 1) AND options IN ('R', 'RP')
   AND target_path IN (@src, CONCAT('https://www.tertiarycourses.com.sg/', @src))
   AND request_path <> @dst;

UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @dst)
 WHERE @ok AND store_id = 1 AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @src);
