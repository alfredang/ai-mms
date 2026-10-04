-- 1752: TGS-2026061321 "WSQ - Customer-Centric Branding and Communication
-- Tactics" is a soft-skills / customer-service course: move it out of WSQ IT &
-- Security Courses ('wsq-it-security-courses') into WSQ Soft Skills Courses
-- ('wsq-soft-skills-courses') and the Customer Service topic page
-- ('customer-service-training'). There is no "WSQ Customer Service" category.
--
-- 1. Add it to WSQ Soft Skills, its parent WSQ Soft Skill & Business (anchor;
--    no reindex runs at deploy, so base + index rows are written here) and
--    Customer Service. On each page it takes MAX(TGS- position)+1 and any
--    non-TGS row at or after that slot shifts down one, keeping funded courses
--    first (see 1269 -> 1273). Customer Service's parent Business & Soft Skills
--    already lists it directly.
-- 2. Remove it from WSQ IT & Security. Parent-anchor check: it sits in no child
--    of WSQ IT & Security, so the direct row is the only thing listing it there.
--    WSQ Funded Courses (292) and Communication keep their rows.
--
-- Business-key lookups only (url_key + TRIM(sku)); no-op on partner sites.
-- Idempotent: each shift runs only while the course is not yet on that page.

SET @ss := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-soft-skills-courses' LIMIT 1);
SET @ssb := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-soft-skill-and-critical-core-skill-project-management-courses' LIMIT 1);
SET @cs := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='customer-service-training' LIMIT 1);
SET @its := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-it-security-courses' LIMIT 1);
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2026061321' LIMIT 1);

-- 1a. WSQ Soft Skills ----------------------------------------------------------------

SET @cat := @ss;
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

-- 1b. WSQ Soft Skill & Business (parent) ----------------------------------------------------------------

SET @cat := @ssb;
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

-- 1c. Customer Service ----------------------------------------------------------------

SET @cat := @cs;
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
