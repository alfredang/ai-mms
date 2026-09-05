-- 1339: Add the two "AI for IT Security" WSQ courses to WSQ AI Security Courses
-- (url_key 'wsq-ai-security-courses', 284 on SG).
--
--   TGS-2024048311  WSQ - AI for IT Security
--   TGS-2023039344  WSQ - AI for IT Security Professionals
--
-- Verified on SG prod 2026-09-05: the category holds 8 courses, ALL TGS-, and
-- neither of these two is a member. Because the category is all-TGS, appending
-- at MAX(position)+1 / +2 is safe (no C-block to land under); the nightly sweep
-- keeps TGS relative order. Its parent WSQ AI Courses (325) picks the two up by
-- anchor inheritance at the next reindex.
--
-- Business-key lookups only (url_key + SKU). Partner-safe: TGS- SKUs do not
-- exist on MY/GH, so the inserts are clean no-ops there. Idempotent.

SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'wsq-ai-security-courses' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS tmp_1339_adds;
CREATE TEMPORARY TABLE tmp_1339_adds (sku VARCHAR(64) PRIMARY KEY, seq TINYINT NOT NULL);
INSERT INTO tmp_1339_adds (sku, seq) VALUES
  ('TGS-2024048311', 1),
  ('TGS-2023039344', 2);

SET @max_pos := (SELECT COALESCE(MAX(position), 0) FROM catalog_category_product WHERE category_id = @cat);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, p.entity_id, @max_pos + a.seq
FROM tmp_1339_adds a
JOIN catalog_product_entity p ON p.sku = a.sku
WHERE @cat IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, p.entity_id, @max_pos + a.seq, 1, s.store_id, MAX(i.visibility)
FROM tmp_1339_adds a
JOIN catalog_product_entity p ON p.sku = a.sku
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @cat IS NOT NULL
GROUP BY p.entity_id, s.store_id;

DROP TEMPORARY TABLE IF EXISTS tmp_1339_adds;
