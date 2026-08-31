-- 1289: Add TGS-2023037544 "WSQ - Generative AI for 3D Modeling" to WSQ
-- Generative AI Courses (url_key 'wsq-generative-ai-courses').
--
-- It was 4th in the requested order pinned by 1288, but had NO membership row
-- for that category — so the ORDER BY matched zero rows for it and the course
-- stayed missing from the page (live and enabled, status=1, visibility=4, and
-- present in 14 other categories). Same failure mode as 1264/1279.
--
-- Assigned here and pinned to the slot 1288 reserved for it (-9, between
-- "Generative AI for 3D Design" at -10 and "Project Management with Generative
-- AI" at -8), so the requested order is restored exactly without renumbering
-- anything else.
--
-- The category is all-TGS, so this cannot break the funded-first rule.
-- Business-key lookups only. Idempotent.

SET @gen := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-generative-ai-courses' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @gen, p.entity_id, -9
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2023037544' AND @gen IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @gen, p.entity_id, -9, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'TGS-2023037544' AND @gen IS NOT NULL
GROUP BY p.entity_id, s.store_id;

-- Ensure the position is right even if the row already existed.
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = -9
WHERE cp.category_id = @gen AND @gen IS NOT NULL AND p.sku = 'TGS-2023037544';

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = -9
WHERE i.category_id = @gen AND @gen IS NOT NULL AND p.sku = 'TGS-2023037544';
