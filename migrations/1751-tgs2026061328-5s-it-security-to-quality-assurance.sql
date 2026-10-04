-- 1751: TGS-2026061328 "WSQ - Maximizing Productivity Outcomes Using 5S
-- Framework" is a quality / lean course: move it from WSQ IT & Security
-- Courses ('wsq-it-security-courses') to WSQ Quality Assurance Courses
-- ('wsq-quality-assurance-courses').
--
-- 1. Add it to WSQ Quality Assurance AND its parent WSQ Mfg & Green
--    ('wsq-finance-mfg-green-courses') — 16 of the 17 existing QA courses carry
--    that direct parent row too, and no reindex runs at deploy, so both base
--    and index rows are written here. On each page it takes
--    MAX(TGS- position)+1 and any non-TGS row at or after that slot shifts down
--    one, keeping funded courses first (see 1269 -> 1273).
-- 2. Remove it from WSQ IT & Security. Parent-anchor check: it sits in no child
--    of WSQ IT & Security, so the direct row is the only thing listing it there.
--    WSQ Funded Courses (292) keeps its direct row.
--
-- Business-key lookups only (url_key + TRIM(sku)); no-op on partner sites.
-- Idempotent: each shift runs only while the course is not yet on that page.

SET @qa := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-quality-assurance-courses' LIMIT 1);
SET @mfg := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-finance-mfg-green-courses' LIMIT 1);
SET @its := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-it-security-courses' LIMIT 1);
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2026061328' LIMIT 1);

-- 1a. WSQ Quality Assurance -----------------------------------------------------

SET @cat := @qa;
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;

-- 1b. WSQ Mfg & Green (parent) ---------------------------------------------------

SET @cat := @mfg;
SET @todo := (SELECT COUNT(*) = 0 FROM catalog_category_product WHERE category_id = @cat AND product_id = @pid);
SET @slot := (SELECT COALESCE(MAX(cp.position),0) + 1 FROM catalog_category_product cp
  JOIN catalog_product_entity p ON p.entity_id = cp.product_id
  WHERE cp.category_id = @cat AND TRIM(p.sku) LIKE 'TGS-%');

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND cp.category_id = @cat AND cp.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 1
WHERE @todo = 1 AND @cat IS NOT NULL AND @pid IS NOT NULL
  AND i.category_id = @cat AND i.position >= @slot AND TRIM(p.sku) NOT LIKE 'TGS-%';

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @pid, @slot FROM DUAL WHERE @cat IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @pid, @slot, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @cat IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;

-- 2. Remove from WSQ IT & Security -------------------------------------------------

DELETE FROM catalog_category_product
WHERE category_id = @its AND product_id = @pid AND @its IS NOT NULL;

DELETE FROM catalog_category_product_index
WHERE category_id = @its AND product_id = @pid AND @its IS NOT NULL;
