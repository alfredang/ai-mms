-- "AI Vibe Coding Series" category: list ONLY non-WSQ (C-prefix) courses whose
-- course NAME contains "Vibe Coding". Removes C-prefix members that were pulled
-- in by the badge backfill (migration 541) but are not titled as series courses.
--
-- WSQ (TGS-) courses are NEVER touched -- they stay in the category as-is.
-- Partner (M-prefix) rows are likewise untouched (guarded by the sku LIKE 'C%').
-- Category resolved by NAME so the id may differ per site (partner-safe).
-- Idempotent: re-running deletes nothing further. No content line ends in ';'.

SET @cat_vibe := (
  SELECT cv.entity_id
  FROM catalog_category_entity_varchar cv
  JOIN eav_attribute ca
    ON ca.attribute_id = cv.attribute_id AND ca.entity_type_id = 3 AND ca.attribute_code = 'name'
  WHERE cv.store_id = 0 AND cv.value = 'AI Vibe Coding Series'
  LIMIT 1);

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');

-- Also clear the badge on those courses so migration 541 does not re-add them.
UPDATE catalog_product_entity_varchar bv
JOIN catalog_product_entity p ON p.entity_id = bv.entity_id
JOIN catalog_product_entity_varchar nv
  ON nv.entity_id = p.entity_id AND nv.store_id = 0 AND nv.attribute_id = @a_name
SET bv.value = NULL
WHERE bv.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge')
  AND p.sku LIKE 'C%'
  AND nv.value NOT LIKE '%Vibe Coding%'
  AND @cat_vibe IS NOT NULL;

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
JOIN catalog_product_entity_varchar nv
  ON nv.entity_id = p.entity_id AND nv.store_id = 0 AND nv.attribute_id = @a_name
WHERE cp.category_id = @cat_vibe
  AND p.sku LIKE 'C%'
  AND nv.value NOT LIKE '%Vibe Coding%'
  AND @cat_vibe IS NOT NULL;

DELETE cpi FROM catalog_category_product_index cpi
JOIN catalog_product_entity p ON p.entity_id = cpi.product_id
JOIN catalog_product_entity_varchar nv
  ON nv.entity_id = p.entity_id AND nv.store_id = 0 AND nv.attribute_id = @a_name
WHERE cpi.category_id = @cat_vibe
  AND p.sku LIKE 'C%'
  AND nv.value NOT LIKE '%Vibe Coding%'
  AND @cat_vibe IS NOT NULL;
