-- 1222: Remove "Multi AI Agents System for Digital Marketing" (C349) from the
-- AI Vibe Coding Series.
--
-- C349 was "AI Vibe Coding for Multi Agent AI Systems" until 1214 converted
-- it; the new name no longer belongs in the Vibe Coding line. It is ALREADY a
-- member of the Multi AI Agents Series (pinned there by 1214), so this
-- migration is the removal only — the defensive INSERT below is a no-op where
-- the assignment already exists.
--
-- The AI Vibe Coding Series carries a curated non-WSQ order; removing one row
-- just closes the gap, so no re-pin is needed there.
--
-- Business-key lookups; SG-only SKU/url_keys (partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @vibe := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1);
SET @multi := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'multi-agents-series' LIMIT 1);

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @vibe
  AND p.sku = 'C349';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @vibe
  AND p.sku = 'C349';

-- Defensive: ensure it is in the Multi AI Agents Series (it already is).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @multi, p.entity_id, 102
FROM catalog_product_entity p
WHERE @multi IS NOT NULL
  AND p.sku = 'C349';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @multi, p.entity_id, 102, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @multi IS NOT NULL
  AND p.sku = 'C349'
GROUP BY p.entity_id, s.store_id;
