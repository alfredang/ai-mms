-- 1302: Add "WSQ - Fundamentals of Microsoft Project Management" (TGS-2024042307)
-- to the Microsoft Project Courses category (/microsoft-project-courses.html).
--
-- The category currently holds only C325 (non-WSQ) at position 1, so the funded
-- course is inserted ABOVE the C-block (MIN(position) - 1) per the funded-first
-- rule — never MAX(position)+1 in a mixed category (see 1269 -> 1273 incident).
-- The nightly ordering sweep compacts positions to a dense 1..N.
--
-- Index mirror is written directly (the storefront reads
-- catalog_category_product_index, and no reindex runs at deploy).
--
-- Business-key lookups only. Partner-safe: on MY/GH the TGS- SKU does not
-- exist, @pid is NULL and every statement no-ops. Idempotent.

SET @uk := (SELECT attribute_id FROM eav_attribute
            WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1);

SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
             WHERE store_id = 0 AND attribute_id = @uk
               AND value = 'microsoft-project-courses' LIMIT 1);

SET @pid := (SELECT entity_id FROM catalog_product_entity
             WHERE sku = 'TGS-2024042307' LIMIT 1);

-- Position above the whole existing block (excluding our own row on re-run).
SET @newpos := (SELECT COALESCE(MIN(position), 2) - 1
                FROM catalog_category_product
                WHERE category_id = @cat AND product_id <> @pid);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @newpos FROM DUAL
WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

-- Mirror into the index for every store on this instance where the product is
-- already indexed (visibility copied from the product's existing index rows).
INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @newpos, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE i.product_id = @pid AND i.store_id > 0
  AND @cat IS NOT NULL AND @pid IS NOT NULL
GROUP BY i.store_id
ON DUPLICATE KEY UPDATE position = VALUES(position);
