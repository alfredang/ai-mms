-- 1197: Follow-up to 1196 — collision-free slugs for two subcategories.
--
-- The catalog_url reindex suffixed the 1196 slugs to ai-for-finance-1.html /
-- ai-for-healthcare-1.html because the plain paths belong to the PRODUCT
-- pages of courses C207 (AI for Finance) and C1018 (AI for Healthcare),
-- which keep their URLs. Rename the two subcategories to the sibling
-- convention instead:
--   ai-for-finance    -> ai-for-finance-courses
--   ai-for-healthcare -> ai-for-healthcare-courses
--
-- The stale category rewrites (the -1 ones) are removed so the next
-- catalog_url reindex regenerates clean ones. Categories are resolved by
-- url_key, which exists only on SG (created by the SG-guarded 1196) — clean
-- no-op on partner instances. Idempotent via COALESCE on the new slug.

SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_path');

SET @fin := COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_urlkey AND v.store_id = 0 AND v.value = 'ai-for-finance-courses' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_urlkey AND v.store_id = 0 AND v.value = 'ai-for-finance' LIMIT 1)
);
SET @health := COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_urlkey AND v.store_id = 0 AND v.value = 'ai-for-healthcare-courses' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_urlkey AND v.store_id = 0 AND v.value = 'ai-for-healthcare' LIMIT 1)
);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-finance-courses'
WHERE entity_id = @fin AND attribute_id = @a_urlkey AND @fin IS NOT NULL;

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-finance-courses.html'
WHERE entity_id = @fin AND attribute_id = @a_urlpath AND @fin IS NOT NULL;

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-healthcare-courses'
WHERE entity_id = @health AND attribute_id = @a_urlkey AND @health IS NOT NULL;

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-healthcare-courses.html'
WHERE entity_id = @health AND attribute_id = @a_urlpath AND @health IS NOT NULL;

-- Drop the stale suffixed category rewrites; the catalog_url reindex
-- regenerates clean ones for the new slugs. (Never touch the C207/C1018
-- product rewrites.)
DELETE FROM core_url_rewrite
WHERE category_id IN (@fin, @health)
  AND product_id IS NULL
  AND is_system = 1
  AND @fin IS NOT NULL;

-- Flat mirror (store 1), guarded; 'DO 0' no-op.
SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
);

SET @sql := IF(@has_flat > 0 AND @fin IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET url_key = ''ai-for-finance-courses'', url_path = ''ai-for-finance-courses.html'' WHERE entity_id = @fin',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

SET @sql := IF(@has_flat > 0 AND @health IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET url_key = ''ai-for-healthcare-courses'', url_path = ''ai-for-healthcare-courses.html'' WHERE entity_id = @health',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;
