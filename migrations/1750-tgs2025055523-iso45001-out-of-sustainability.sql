-- 1750: TGS-2025055523 "WSQ - ISO 45001 Internal Auditor Training" is an
-- occupational health & safety standard, not a sustainability course.
--
-- 1. Safety net: member of WSQ Quality Assurance Courses
--    ('wsq-quality-assurance-courses'). On SG it is ALREADY a direct member —
--    verified on prod 2026-10-04 — so the INSERT IGNOREs no-op there.
-- 2. Remove it from Sustainability ('sustainability-and-environment-courses').
--    Parent-anchor check: the parent Sustainability & ESG keeps its direct row
--    on purpose — the course is still reachable there via ISO Standards and
--    ISO Internal Auditor.
--
-- Business-key lookups only (url_key + TRIM(sku)); no-op on partner sites.
-- Idempotent.

SET @qa := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-quality-assurance-courses' LIMIT 1);
SET @sus := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='sustainability-and-environment-courses' LIMIT 1);
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2025055523' LIMIT 1);

-- 1. Ensure membership in WSQ Quality Assurance Courses -----------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @qa, @pid,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @qa)
FROM DUAL WHERE @qa IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @qa, @pid,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @qa),
       1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @qa IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;

-- 2. Remove from Sustainability -------------------------------------------------

DELETE FROM catalog_category_product
WHERE category_id = @sus AND product_id = @pid AND @sus IS NOT NULL;

DELETE FROM catalog_category_product_index
WHERE category_id = @sus AND product_id = @pid AND @sus IS NOT NULL;
