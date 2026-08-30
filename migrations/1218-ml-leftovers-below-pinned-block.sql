-- 1218: Keep the AI for Machine Learning non-WSQ leftovers below the curated
-- block, and seat AI-300 in the AI Applications Series parent order.
--
-- Why this is needed: the curated exemption preserves the non-WSQ ORDER but
-- the sweep still renumbers the whole listing to 1..N. Members that were
-- pushed to 200+ (CompTIA DataAI, CompTIA SecAI+, AI for HR) come back
-- renumbered to low positions ABOVE the 101+ curated block, so they lead the
-- non-WSQ section again. Pinning them explicitly at the END of the curated
-- range fixes the order under both the sweep and a full reindex — the 200+
-- "park them out of the way" trick does not survive a renumber.
--
-- AI-300 (C1762) was added to the AI Applications Series by 1217 but kept an
-- unpinned position, so it sorted into the middle of the listing; it is
-- pinned here into the Machine Learning group.
--
-- SG-only SKUs/url_keys (partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @ml := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-machine-learning' LIMIT 1);
SET @apps := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) AI for Machine Learning — full curated order, leftovers pinned last.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C430'  THEN 101
  WHEN 'C592'  THEN 102
  WHEN 'C193'  THEN 103
  WHEN 'C188'  THEN 104
  WHEN 'C539'  THEN 105
  WHEN 'C1071' THEN 106
  WHEN 'C926'  THEN 107
  WHEN 'C1759' THEN 108
  WHEN 'C1762' THEN 109
  WHEN 'C19'   THEN 110
  WHEN 'C1330' THEN 111
  WHEN 'C279'  THEN 112
  WHEN 'C476'  THEN 113
  WHEN 'C1750' THEN 114
  WHEN 'C820'  THEN 115
END
WHERE cp.category_id = @ml
  AND p.sku IN ('C430','C592','C193','C188','C539','C1071','C926','C1759','C1762',
                'C19','C1330','C279','C476','C1750','C820');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C430'  THEN 101
  WHEN 'C592'  THEN 102
  WHEN 'C193'  THEN 103
  WHEN 'C188'  THEN 104
  WHEN 'C539'  THEN 105
  WHEN 'C1071' THEN 106
  WHEN 'C926'  THEN 107
  WHEN 'C1759' THEN 108
  WHEN 'C1762' THEN 109
  WHEN 'C19'   THEN 110
  WHEN 'C1330' THEN 111
  WHEN 'C279'  THEN 112
  WHEN 'C476'  THEN 113
  WHEN 'C1750' THEN 114
  WHEN 'C820'  THEN 115
END
WHERE i.category_id = @ml
  AND p.sku IN ('C430','C592','C193','C188','C539','C1071','C926','C1759','C1762',
                'C19','C1330','C279','C476','C1750','C820');

-- ---------------------------------------------------------------------------
-- 2) AI Applications Series parent — seat AI-300 after AI-200 in the
--    Machine Learning group (which runs 122..133 after 1210).
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C430'  THEN 122
  WHEN 'C592'  THEN 123
  WHEN 'C193'  THEN 124
  WHEN 'C188'  THEN 125
  WHEN 'C539'  THEN 126
  WHEN 'C1071' THEN 127
  WHEN 'C926'  THEN 128
  WHEN 'C1759' THEN 129
  WHEN 'C1762' THEN 130
  WHEN 'C19'   THEN 131
  WHEN 'C1330' THEN 132
  WHEN 'C279'  THEN 133
  WHEN 'C476'  THEN 134
  WHEN 'C1750' THEN 135
END
WHERE cp.category_id = @apps
  AND p.sku IN ('C430','C592','C193','C188','C539','C1071','C926','C1759','C1762',
                'C19','C1330','C279','C476','C1750');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C430'  THEN 122
  WHEN 'C592'  THEN 123
  WHEN 'C193'  THEN 124
  WHEN 'C188'  THEN 125
  WHEN 'C539'  THEN 126
  WHEN 'C1071' THEN 127
  WHEN 'C926'  THEN 128
  WHEN 'C1759' THEN 129
  WHEN 'C1762' THEN 130
  WHEN 'C19'   THEN 131
  WHEN 'C1330' THEN 132
  WHEN 'C279'  THEN 133
  WHEN 'C476'  THEN 134
  WHEN 'C1750' THEN 135
END
WHERE i.category_id = @apps
  AND p.sku IN ('C430','C592','C193','C188','C539','C1071','C926','C1759','C1762',
                'C19','C1330','C279','C476','C1750');
