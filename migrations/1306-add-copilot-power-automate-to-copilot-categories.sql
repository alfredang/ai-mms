-- 1306: Add "WSQ - Copilot for Power Automate" (TGS-2024042588) to the two
-- Microsoft Copilot category listings:
--   * Microsoft Copilot Series   (/microsoft-copilot-series.html)
--   * Microsoft Copilot Courses  (/microsoft-copilot-courses.html)
--
-- The course was repurposed from PL-200 by migration 957, which dropped it from
-- the eight PL-200-specific listings but never added it to the Copilot ones.
-- Its content (Copilot Studio agents driving agentic Power Automate workflows)
-- belongs in both.
--
-- ORDERING: both categories are MIXED — a funded TGS- block on top, then a
-- C-prefix block. Funded-first is the hard rule, so the new row is appended to
-- the END OF THE TGS- BLOCK (max funded position + 1) and every row at or below
-- that position is shifted down by 1 to make room. NOT MAX(position)+1, which
-- would land it under the C-block (see the 1269 -> 1273 incident).
--
-- Index mirror is written directly (the storefront reads
-- catalog_category_product_index, and no reindex runs at deploy).
--
-- Business-key lookups only. Partner-safe: on MY/GH the TGS- SKU does not
-- exist, @pid is NULL and every statement no-ops. Idempotent — the shift is
-- skipped on re-run because the product row already exists.

SET @uk := (SELECT attribute_id FROM eav_attribute
            WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1);

SET @pid := (SELECT entity_id FROM catalog_product_entity
             WHERE sku = 'TGS-2024042588' LIMIT 1);

-- =============================================== Microsoft Copilot Series (357)

SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
             WHERE store_id = 0 AND attribute_id = @uk
               AND value = 'microsoft-copilot-series' LIMIT 1);

-- Already a member? Then this is a re-run: skip the shift entirely.
SET @have := (SELECT COUNT(*) FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid);

-- Slot = one past the last funded (TGS-) course in this category.
SET @newpos := (SELECT COALESCE(MAX(cp.position), 0) + 1
                FROM catalog_category_product cp
                JOIN catalog_product_entity e ON e.entity_id = cp.product_id
                WHERE cp.category_id = @cat AND e.sku LIKE 'TGS-%'
                  AND cp.product_id <> @pid);

UPDATE catalog_category_product
   SET position = position + 1
 WHERE category_id = @cat AND position >= @newpos
   AND @cat IS NOT NULL AND @pid IS NOT NULL AND @have = 0;

UPDATE catalog_category_product_index
   SET position = position + 1
 WHERE category_id = @cat AND position >= @newpos
   AND @cat IS NOT NULL AND @pid IS NOT NULL AND @have = 0;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @newpos FROM DUAL
WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @newpos, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND i.store_id > 0
  AND @cat IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- ============================================== Microsoft Copilot Courses (137)

SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
             WHERE store_id = 0 AND attribute_id = @uk
               AND value = 'microsoft-copilot-courses' LIMIT 1);

SET @have := (SELECT COUNT(*) FROM catalog_category_product
              WHERE category_id = @cat AND product_id = @pid);

SET @newpos := (SELECT COALESCE(MAX(cp.position), 0) + 1
                FROM catalog_category_product cp
                JOIN catalog_product_entity e ON e.entity_id = cp.product_id
                WHERE cp.category_id = @cat AND e.sku LIKE 'TGS-%'
                  AND cp.product_id <> @pid);

UPDATE catalog_category_product
   SET position = position + 1
 WHERE category_id = @cat AND position >= @newpos
   AND @cat IS NOT NULL AND @pid IS NOT NULL AND @have = 0;

UPDATE catalog_category_product_index
   SET position = position + 1
 WHERE category_id = @cat AND position >= @newpos
   AND @cat IS NOT NULL AND @pid IS NOT NULL AND @have = 0;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @newpos FROM DUAL
WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @newpos, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND i.store_id > 0
  AND @cat IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id
ON DUPLICATE KEY UPDATE position = VALUES(position);
