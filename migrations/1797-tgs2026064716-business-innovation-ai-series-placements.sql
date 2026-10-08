-- 1797: series placements requested 2026-10-08.
--
-- TGS-2026064716  CASL - Business Innovation with Artificial Intelligence
-- added to three AI Series landing pages:
--   generative-ai-series  (Generative AI Series)
--   agentic-ai-series     (Agentic AI Series)
--   ai-agents-series      (AI Agents Series)
-- It was already on AI Applications Series and AI Courses (the anchor parent of
-- all three), so the parent index rows already exist; INSERT IGNORE keeps it so.
--
-- Funded TGS- course goes above the C- block (MIN position); the nightly ordering
-- sweep settles the final order. Membership only; status and visibility
-- untouched. Categories by url_key, product by TRIM(sku); no-op where absent.
-- Idempotent.

DROP TEMPORARY TABLE IF EXISTS tmp_1797_add;
CREATE TEMPORARY TABLE tmp_1797_add (sku VARCHAR(64) NOT NULL, url_key VARCHAR(255) NOT NULL);
INSERT INTO tmp_1797_add (sku, url_key) VALUES
  ('TGS-2026064716', 'generative-ai-series'),
  ('TGS-2026064716', 'agentic-ai-series'),
  ('TGS-2026064716', 'ai-agents-series');

DROP TEMPORARY TABLE IF EXISTS tmp_1797_res;
CREATE TEMPORARY TABLE tmp_1797_res AS
SELECT p.entity_id AS product_id, v.entity_id AS category_id, c.parent_id
FROM tmp_1797_add m
JOIN catalog_product_entity p ON TRIM(p.sku) = m.sku
JOIN catalog_category_entity_varchar v ON v.store_id = 0 AND v.value = m.url_key
JOIN eav_attribute a ON a.attribute_id = v.attribute_id
  AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
JOIN catalog_category_entity c ON c.entity_id = v.entity_id;

DROP TEMPORARY TABLE IF EXISTS tmp_1797_pos;
CREATE TEMPORARY TABLE tmp_1797_pos AS
SELECT cp.category_id, MIN(cp.position) AS minp
FROM catalog_category_product cp
WHERE cp.category_id IN (SELECT DISTINCT category_id FROM tmp_1797_res)
GROUP BY cp.category_id;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT r.category_id, r.product_id, COALESCE(x.minp, 0)
FROM tmp_1797_res r LEFT JOIN tmp_1797_pos x ON x.category_id = r.category_id;

-- Listing index: the direct row ...
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, s.store_id,
  (SELECT MAX(i2.visibility) FROM catalog_category_product_index i2
   WHERE i2.product_id = cp.product_id AND i2.store_id = s.store_id)
FROM tmp_1797_res r
JOIN catalog_category_product cp ON cp.category_id = r.category_id AND cp.product_id = r.product_id
JOIN core_store s ON s.store_id > 0
WHERE EXISTS (SELECT 1 FROM catalog_category_product_index i3
              WHERE i3.product_id = cp.product_id AND i3.store_id = s.store_id);

-- ... and the anchor parent's inherited row (AI Courses).
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT r.parent_id, r.product_id, 0, 0, s.store_id,
  (SELECT MAX(i2.visibility) FROM catalog_category_product_index i2
   WHERE i2.product_id = r.product_id AND i2.store_id = s.store_id)
FROM tmp_1797_res r
JOIN catalog_category_entity pc ON pc.entity_id = r.parent_id AND pc.level >= 2 AND pc.entity_id <> 2
JOIN core_store s ON s.store_id > 0
WHERE EXISTS (SELECT 1 FROM catalog_category_product_index i3
              WHERE i3.product_id = r.product_id AND i3.store_id = s.store_id);

DROP TEMPORARY TABLE IF EXISTS tmp_1797_pos;
DROP TEMPORARY TABLE IF EXISTS tmp_1797_res;
DROP TEMPORARY TABLE IF EXISTS tmp_1797_add;
