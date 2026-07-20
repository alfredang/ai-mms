-- 513: Convert course category pages to 2-column layout with layered-nav
-- (anchor) filters on the left: Course Type (software), Session
-- (progromming_language), Level (level).
--
-- Scope: all PRODUCTS-mode categories. PAGE-mode landing categories
-- (Hiring forms, Group Training, etc.) keep their one_column layout.
-- All lookups are by attribute_code so this is safe on partner DBs
-- whose attribute_ids differ. Every statement is idempotent.

-- 1) page_layout: one_column -> two_columns_left for non-PAGE categories (all store scopes)
UPDATE catalog_category_entity_varchar pl
JOIN eav_attribute pa ON pa.attribute_id = pl.attribute_id
  AND pa.attribute_code = 'page_layout'
  AND pa.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category')
LEFT JOIN catalog_category_entity_varchar dm ON dm.entity_id = pl.entity_id
  AND dm.store_id = 0
  AND dm.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'display_mode'
    AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category'))
SET pl.value = 'two_columns_left'
WHERE pl.value = 'one_column'
  AND (dm.value IS NULL OR dm.value <> 'PAGE');

-- 2a) is_anchor: flip any existing 0 rows to 1 for non-PAGE categories (all store scopes)
UPDATE catalog_category_entity_int an
JOIN eav_attribute aa ON aa.attribute_id = an.attribute_id
  AND aa.attribute_code = 'is_anchor'
  AND aa.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category')
JOIN catalog_category_entity e ON e.entity_id = an.entity_id AND e.level >= 2
LEFT JOIN catalog_category_entity_varchar dm ON dm.entity_id = an.entity_id
  AND dm.store_id = 0
  AND dm.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'display_mode'
    AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category'))
SET an.value = 1
WHERE an.value = 0
  AND (dm.value IS NULL OR dm.value <> 'PAGE');

-- 2b) is_anchor: insert missing default-scope rows as 1 for non-PAGE categories
INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT e.entity_type_id, aa.attribute_id, 0, e.entity_id, 1
FROM catalog_category_entity e
JOIN eav_attribute aa ON aa.attribute_code = 'is_anchor'
  AND aa.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category')
LEFT JOIN catalog_category_entity_varchar dm ON dm.entity_id = e.entity_id
  AND dm.store_id = 0
  AND dm.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'display_mode'
    AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category'))
LEFT JOIN catalog_category_entity_int ex ON ex.entity_id = e.entity_id
  AND ex.attribute_id = aa.attribute_id AND ex.store_id = 0
WHERE e.level >= 2
  AND (dm.value IS NULL OR dm.value <> 'PAGE')
  AND ex.value_id IS NULL;

-- 3) Ensure the three filter attributes are filterable (with results) in layered nav
UPDATE catalog_eav_attribute c
JOIN eav_attribute a ON a.attribute_id = c.attribute_id
SET c.is_filterable = 1
WHERE a.attribute_code IN ('software', 'progromming_language', 'level')
  AND a.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- 4) Storefront label "Session" for progromming_language (admin keeps "Session (days)")
UPDATE eav_attribute_label l
JOIN eav_attribute a ON a.attribute_id = l.attribute_id
SET l.value = 'Session'
WHERE a.attribute_code = 'progromming_language'
  AND a.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
  AND l.store_id > 0;

INSERT INTO eav_attribute_label (attribute_id, store_id, value)
SELECT a.attribute_id, s.store_id, 'Session'
FROM eav_attribute a
JOIN core_store s ON s.store_id > 0
WHERE a.attribute_code = 'progromming_language'
  AND a.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product')
  AND NOT EXISTS (SELECT 1 FROM eav_attribute_label x WHERE x.attribute_id = a.attribute_id AND x.store_id = s.store_id);
