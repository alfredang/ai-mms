-- 1207: Move WSQ - Generative AI Model Development and Fine Tuning
-- (TGS-2025059025) out of the Generative AI Series and into the
-- AI Infrastructure Series.
--
-- It is appended to the Infrastructure listing's WSQ block (after the 12
-- TGS- courses already pinned there by 1198), so the WSQ/CASL/IBF-before-
-- non-WSQ rule still holds. The Generative AI Series keeps its curated
-- order; removing one TGS- row just closes the gap.
--
-- Business-key lookups; TGS- SKUs do not exist on partner instances (clean
-- no-op). Idempotent.

SET @gen := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'generative-ai-series' LIMIT 1
);
SET @infra := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-infrastructure-series' LIMIT 1
);

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @gen
  AND p.sku = 'TGS-2025059025';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @gen
  AND p.sku = 'TGS-2025059025';

-- Append after the existing pinned WSQ block (max TGS- position + 1), so it
-- lands inside the WSQ section rather than below the non-WSQ courses.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @infra, p.entity_id,
       COALESCE((SELECT MAX(cp2.position)
                 FROM (SELECT * FROM catalog_category_product) cp2
                 JOIN catalog_product_entity p2 ON p2.entity_id = cp2.product_id
                 WHERE cp2.category_id = @infra AND p2.sku LIKE 'TGS-%'), 0) + 1
FROM catalog_product_entity p
WHERE @infra IS NOT NULL
  AND p.sku = 'TGS-2025059025';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @infra, p.entity_id,
       COALESCE((SELECT MAX(i2.position)
                 FROM (SELECT * FROM catalog_category_product_index) i2
                 JOIN catalog_product_entity p2 ON p2.entity_id = i2.product_id
                 WHERE i2.category_id = @infra AND i2.store_id = s.store_id
                   AND p2.sku LIKE 'TGS-%'), 0) + 1,
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @infra IS NOT NULL
  AND p.sku = 'TGS-2025059025'
GROUP BY p.entity_id, s.store_id;
