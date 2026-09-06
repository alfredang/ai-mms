-- 1342: Add three funded courses to the Microsoft Copilot Series page
--       (url_key 'microsoft-copilot-series', 357 on SG), listed BEFORE the
--       non-WSQ block, in the owner's requested order:
--
--   6 TGS-2024045795  WSQ  - Agentic AI for HR
--   7 TGS-2024051421  WSQ  - Generative AI for Interviewing
--   8 TGS-2026065050  CASL - Generative AI for Finance and Fintech
--
-- Verified on SG prod 2026-09-06: 357 holds 13 rows — a TGS- block at 1..5 and
-- a CURATED C-block at 6..13 (357 is in mmd/category_ordering/curated_url_keys,
-- so the C order must NOT be re-sorted). None of the three courses is a member
-- (no base row, no index row). 357 is a leaf, so anchor inheritance is not a
-- factor. Never MAX(position)+1 here — that lands a funded course under the
-- C-block (1269 incident).
--
-- Approach: shift every non-TGS row by +3 (relative order kept), then insert
-- the three at TGS_MAX+1..+3, in BOTH catalog_category_product and the index.
--
-- Business-key lookups only (url_key + SKU). Partner-safe: the TGS- SKUs do not
-- exist on MY/GH, so the whole file is a clean no-op there (guarded on @n = 3).
-- Idempotent: the guard also skips a re-run once the rows exist.

SET @a_ukey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @a_ukey AND value = 'microsoft-copilot-series' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS tmp_1342_add;
CREATE TEMPORARY TABLE tmp_1342_add (sku VARCHAR(64) PRIMARY KEY, seq TINYINT NOT NULL, product_id INT NULL);
INSERT INTO tmp_1342_add (sku, seq) VALUES
  ('TGS-2024045795', 1),
  ('TGS-2024051421', 2),
  ('TGS-2026065050', 3);
UPDATE tmp_1342_add t JOIN catalog_product_entity p ON p.sku = t.sku SET t.product_id = p.entity_id;

-- Number of courses that exist here AND are not yet members of the category.
SET @n := (SELECT COUNT(*) FROM tmp_1342_add t
  WHERE t.product_id IS NOT NULL AND @cat IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM catalog_category_product cp WHERE cp.category_id = @cat AND cp.product_id = t.product_id));

SET @tgs_max := (SELECT COALESCE(MAX(cp.position), 0) FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id AND e.sku LIKE 'TGS-%'
  WHERE cp.category_id = @cat);

-- 1. Make room: shift every non-TGS row below the funded block by @n.
UPDATE catalog_category_product cp
JOIN catalog_product_entity e ON e.entity_id = cp.product_id
SET cp.position = cp.position + @n
WHERE cp.category_id = @cat AND @cat IS NOT NULL AND @n = 3
  AND e.sku NOT LIKE 'TGS-%' AND cp.position > @tgs_max;

UPDATE catalog_category_product_index i
JOIN catalog_product_entity e ON e.entity_id = i.product_id
SET i.position = i.position + @n
WHERE i.category_id = @cat AND @cat IS NOT NULL AND @n = 3
  AND e.sku NOT LIKE 'TGS-%' AND i.position > @tgs_max;

-- 2. Insert the three at the tail of the TGS- block.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, t.product_id, @tgs_max + t.seq
FROM tmp_1342_add t
WHERE @cat IS NOT NULL AND @n = 3 AND t.product_id IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, t.product_id, @tgs_max + t.seq, 1, s.store_id, MAX(i.visibility)
FROM tmp_1342_add t
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = t.product_id AND i.store_id = s.store_id
WHERE @cat IS NOT NULL AND @n = 3 AND t.product_id IS NOT NULL
GROUP BY t.product_id, t.seq, s.store_id;

DROP TEMPORARY TABLE IF EXISTS tmp_1342_add;
