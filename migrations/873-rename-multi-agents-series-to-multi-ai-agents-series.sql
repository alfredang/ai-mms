-- 873: Rename category "Multi Agents Series" -> "Multi AI Agents Series"
-- (AI Series parent 252; SG /multi-agents-series.html).
--
-- Display name + meta_title only. url_key is intentionally UNTOUCHED:
-- the slug "multi-agents-series" still reads correctly for the new name, and
-- changing it would force 301s for the category plus ~20 product rewrites
-- already keyed on multi-agents-series/... (see 567 / the 301-guard rule).
--
-- Idempotent: matched on url_key + old value, so a re-run updates 0 rows.
-- Partner-safe: resolved by url_key, not entity_id; 0 rows where the category
-- is absent or already renamed.

SET @cat_type_id = (SELECT entity_type_id FROM eav_entity_type
                    WHERE entity_type_code = 'catalog_category');
SET @name_attr   = (SELECT attribute_id FROM eav_attribute
                    WHERE attribute_code = 'name' AND entity_type_id = @cat_type_id);
SET @meta_attr   = (SELECT attribute_id FROM eav_attribute
                    WHERE attribute_code = 'meta_title' AND entity_type_id = @cat_type_id);
SET @url_attr    = (SELECT attribute_id FROM eav_attribute
                    WHERE attribute_code = 'url_key' AND entity_type_id = @cat_type_id);

-- name: "Multi Agents Series" -> "Multi AI Agents Series"
UPDATE catalog_category_entity_varchar v
JOIN catalog_category_entity_varchar uk
  ON uk.entity_id = v.entity_id
 AND uk.attribute_id = @url_attr
SET v.value = 'Multi AI Agents Series'
WHERE v.attribute_id = @name_attr
  AND uk.value = 'multi-agents-series'
  AND v.value = 'Multi Agents Series';

-- meta_title: "Multi Agents Series Courses" -> "Multi AI Agents Series Courses"
-- (bare title; MMD_Seotitle appends the store brand at render time)
UPDATE catalog_category_entity_varchar v
JOIN catalog_category_entity_varchar uk
  ON uk.entity_id = v.entity_id
 AND uk.attribute_id = @url_attr
SET v.value = 'Multi AI Agents Series Courses'
WHERE v.attribute_id = @meta_attr
  AND uk.value = 'multi-agents-series'
  AND v.value = 'Multi Agents Series Courses';

-- description opens with "The Multi Agents Series covers ..." — rename it too,
-- or the page keeps announcing the old series name in its own body copy.
UPDATE catalog_category_entity_text t
JOIN eav_attribute a
  ON a.attribute_id = t.attribute_id
 AND a.attribute_code = 'description'
 AND a.entity_type_id = @cat_type_id
JOIN catalog_category_entity_varchar uk
  ON uk.entity_id = t.entity_id
 AND uk.attribute_id = @url_attr
SET t.value = REPLACE(t.value, 'The Multi Agents Series', 'The Multi AI Agents Series')
WHERE uk.value = 'multi-agents-series'
  AND t.value LIKE '%The Multi Agents Series%';

-- Flat mirror: the storefront (menu, breadcrumb, <title>) reads flat, so the
-- EAV write alone is not enough. Guarded per store table (SG=1, MY=2, GH=3) so
-- a partner DB missing one is a no-op rather than an apply.php abort.
SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_1') > 0,
  "UPDATE catalog_category_flat_store_1 SET name='Multi AI Agents Series', meta_title='Multi AI Agents Series Courses', description=REPLACE(description, 'The Multi Agents Series', 'The Multi AI Agents Series') WHERE url_key='multi-agents-series'", 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_2') > 0,
  "UPDATE catalog_category_flat_store_2 SET name='Multi AI Agents Series', meta_title='Multi AI Agents Series Courses', description=REPLACE(description, 'The Multi Agents Series', 'The Multi AI Agents Series') WHERE url_key='multi-agents-series'", 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_3') > 0,
  "UPDATE catalog_category_flat_store_3 SET name='Multi AI Agents Series', meta_title='Multi AI Agents Series Courses', description=REPLACE(description, 'The Multi Agents Series', 'The Multi AI Agents Series') WHERE url_key='multi-agents-series'", 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Post-deploy: Category Flat Data reindex + cache flush.
