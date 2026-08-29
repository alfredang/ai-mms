-- 1191: Move CASL - Pattern Recognition and Machine Learning with R
-- (TGS-2026064608) out of the AI Vibe Coding Series and into the
-- AI Applications Series. It was already a member of the AI Applications
-- Series on prod, so the INSERTs below are defensive no-ops; the real work
-- is the removal. Business-key lookups; TGS- SKUs do not exist on partner
-- instances (clean no-op). Idempotent.

SET @vibe := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1
);
SET @apps := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1
);

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @vibe
  AND p.sku = 'TGS-2026064608';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @vibe
  AND p.sku = 'TGS-2026064608';

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @apps, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @apps IS NOT NULL
  AND p.sku = 'TGS-2026064608';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @apps, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @apps IS NOT NULL
  AND p.sku = 'TGS-2026064608'
GROUP BY p.entity_id, s.store_id;
