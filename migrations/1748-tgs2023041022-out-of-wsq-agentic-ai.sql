-- 1748: TGS-2023041022 "WSQ - Data Analytics and AI for Healthcare" is an AI
-- application course, not an agentic one.
--
-- 1. Safety net: member of WSQ AI Applications Courses
--    ('wsq-ai-applications-courses'). On SG it is ALREADY a direct member (and
--    of the AI Applications Series page) — verified on prod 2026-10-04 — so the
--    INSERT IGNOREs no-op there.
-- 2. Remove it from WSQ Agentic AI Courses ('wsq-agentic-ai-courses').
--    Parent-anchor check: the parent WSQ AI Courses (325) keeps its direct row
--    on purpose — the course is still reachable there via WSQ AI Applications.
--
-- Business-key lookups only (url_key + TRIM(sku)); no-op on partner sites.
-- Idempotent.

SET @app := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-ai-applications-courses' LIMIT 1);
SET @agt := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-agentic-ai-courses' LIMIT 1);
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2023041022' LIMIT 1);

-- 1. Ensure membership in WSQ AI Applications Courses -------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @app, @pid,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @app)
FROM DUAL WHERE @app IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @app, @pid,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @app),
       1, i.store_id, MAX(i.visibility)
FROM catalog_category_product_index i
WHERE @app IS NOT NULL AND i.product_id = @pid AND i.store_id > 0
GROUP BY i.store_id;

-- 2. Remove from WSQ Agentic AI Courses ---------------------------------------

DELETE FROM catalog_category_product
WHERE category_id = @agt AND product_id = @pid AND @agt IS NOT NULL;

DELETE FROM catalog_category_product_index
WHERE category_id = @agt AND product_id = @pid AND @agt IS NOT NULL;
