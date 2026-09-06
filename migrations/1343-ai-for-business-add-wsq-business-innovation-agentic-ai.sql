-- 1343: Add WSQ - Business Innovation with Agentic AI and AI Agents
--       (TGS-2023037472, /wsq-business-innovation-with-agentic-ai-and-ai-agents.html)
--       to the AI for Business page (url_key 'ai-for-business', 128 on SG),
--       at the tail of the funded block, BEFORE the non-WSQ courses.
--
-- Verified on SG prod 2026-09-07: 128 holds 12 rows — a TGS- block at 1..3 and
-- a CURATED C-block at 4..12 (128 is in mmd/category_ordering/curated_url_keys,
-- so the C order must NOT be re-sorted). The course is not a member (no base
-- row, no index row). 128 is a leaf, so anchor inheritance is not a factor.
-- Never MAX(position)+1 here — that lands a funded course under the C-block
-- (1269 incident).
--
-- Approach (same shape as 1342): shift every non-TGS row by +1 (relative order
-- kept), then insert the course at TGS_MAX+1, in BOTH catalog_category_product
-- and the index.
--
-- Business-key lookups only (url_key + SKU). Partner-safe: the TGS- SKU does not
-- exist on MY/GH, so the whole file is a clean no-op there (guarded on @n = 1).
-- Idempotent: the guard also skips a re-run once the row exists.

SET @a_ukey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @a_ukey AND value = 'ai-for-business' LIMIT 1);
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037472' LIMIT 1);

-- 1 when the course exists here AND is not yet a member of the category.
SET @n := (SELECT COUNT(*) FROM catalog_product_entity p
  WHERE p.entity_id = @pid AND @cat IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM catalog_category_product cp WHERE cp.category_id = @cat AND cp.product_id = @pid));

SET @tgs_max := (SELECT COALESCE(MAX(cp.position), 0) FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id AND e.sku LIKE 'TGS-%'
  WHERE cp.category_id = @cat);

-- 1. Make room: shift every non-TGS row below the funded block by 1.
UPDATE catalog_category_product cp
JOIN catalog_product_entity e ON e.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE cp.category_id = @cat AND @cat IS NOT NULL AND @n = 1
  AND e.sku NOT LIKE 'TGS-%' AND cp.position > @tgs_max;

UPDATE catalog_category_product_index i
JOIN catalog_product_entity e ON e.entity_id = i.product_id
SET i.position = i.position + 1
WHERE i.category_id = @cat AND @cat IS NOT NULL AND @n = 1
  AND e.sku NOT LIKE 'TGS-%' AND i.position > @tgs_max;

-- 2. Insert the course at the tail of the TGS- block.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @tgs_max + 1
WHERE @cat IS NOT NULL AND @n = 1 AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @tgs_max + 1, 1, s.store_id, MAX(i.visibility)
FROM core_store s
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id = s.store_id
WHERE @cat IS NOT NULL AND @n = 1 AND @pid IS NOT NULL AND s.store_id > 0
GROUP BY s.store_id;
