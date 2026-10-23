-- 1842: Add the four Claude certification exam-prep courses to the Claude AI
-- Series (url_key claude-ai-series) as the LAST four entries, in this order:
--   1001. C991  — Claude Certified Associate - Foundations (CCAO-F) Exam Prep
--   1002. C1098 — Claude Certified Developer - Foundations (CCDV-F) Exam Prep
--   1003. C437  — Claude Certified Architect - Foundations (CCAR-F) Exam Prep (already a member; moved)
--   1004. C740  — Claude Certified Architect - Professional (CCAR-P) Exam Prep
--
-- Positions 1001+ sit after every existing member, so the rest of the curated
-- order is untouched. 'claude-ai-series' IS in mmd/category_ordering/curated_url_keys,
-- so the nightly sweep keeps C- rows in position order (it compacts the numbers
-- but not the sequence) and still keeps the TGS- block on top.
--
-- Writes BOTH catalog_category_product (admin source of truth) and
-- catalog_category_product_index (what the listing reads) for every store_id
-- already present for this category. Business-key lookups by url_key / sku: a
-- clean no-op where the category or a SKU is absent. Idempotent.

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'claude-ai-series' LIMIT 1
);

DROP TEMPORARY TABLE IF EXISTS tmp_claude_cert_add;
CREATE TEMPORARY TABLE tmp_claude_cert_add (product_id INT UNSIGNED PRIMARY KEY, pos INT NOT NULL);
INSERT INTO tmp_claude_cert_add (product_id, pos)
SELECT e.entity_id, CASE TRIM(e.sku)
  WHEN 'C991' THEN 1001
  WHEN 'C1098' THEN 1002
  WHEN 'C437' THEN 1003
  WHEN 'C740' THEN 1004
END
FROM catalog_product_entity e
WHERE @cat IS NOT NULL AND TRIM(e.sku) IN ('C991', 'C1098', 'C437', 'C740');

-- ===== base table: insert missing rows, then pin positions =====
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, t.product_id, t.pos FROM tmp_claude_cert_add t;

UPDATE catalog_category_product cp
JOIN tmp_claude_cert_add t ON t.product_id = cp.product_id
SET cp.position = t.pos
WHERE cp.category_id = @cat;

-- ===== storefront index: one row per store already listing this category =====
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, t.product_id, t.pos, 1, s.store_id, s.visibility
FROM tmp_claude_cert_add t
CROSS JOIN (
  SELECT store_id, MAX(visibility) AS visibility
  FROM catalog_category_product_index
  WHERE category_id = @cat
  GROUP BY store_id
) s;

UPDATE catalog_category_product_index i
JOIN tmp_claude_cert_add t ON t.product_id = i.product_id
SET i.position = t.pos
WHERE i.category_id = @cat;

DROP TEMPORARY TABLE IF EXISTS tmp_claude_cert_add;
