-- AI Courses drop-down: move "Microsoft Copilot Series" to the end (after
-- "Codex AI Series"). Menu order = catalog_category_entity.position among
-- siblings; the storefront reads the flat category tables, so mirror there too.
-- Name-resolved (ids differ per site); no-op where the category doesn't exist.
-- Idempotent: only moves it when a sibling sits at or after it.

SET @a_name := (SELECT attribute_id FROM eav_attribute
                WHERE entity_type_id = 3 AND attribute_code = 'name');

SET @ai_parent := (SELECT c.entity_id FROM catalog_category_entity c
  JOIN catalog_category_entity_varchar v ON v.entity_id = c.entity_id
    AND v.store_id = 0 AND v.attribute_id = @a_name
  WHERE v.value = 'AI Courses' AND c.level = 2 LIMIT 1);

SET @copilot := (SELECT c.entity_id FROM catalog_category_entity c
  JOIN catalog_category_entity_varchar v ON v.entity_id = c.entity_id
    AND v.store_id = 0 AND v.attribute_id = @a_name
  WHERE v.value = 'Microsoft Copilot Series' AND c.parent_id = @ai_parent LIMIT 1);

SET @max_sibling := (SELECT MAX(position) FROM catalog_category_entity
  WHERE parent_id = @ai_parent AND entity_id <> @copilot);

UPDATE catalog_category_entity
SET position = @max_sibling + 1
WHERE entity_id = @copilot AND @max_sibling IS NOT NULL AND position <= @max_sibling;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1') > 0
             AND @copilot IS NOT NULL,
  CONCAT('UPDATE catalog_category_flat_store_1 f JOIN catalog_category_entity e ON e.entity_id = f.entity_id SET f.position = e.position WHERE f.entity_id = ', @copilot),
  'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_2') > 0
             AND @copilot IS NOT NULL,
  CONCAT('UPDATE catalog_category_flat_store_2 f JOIN catalog_category_entity e ON e.entity_id = f.entity_id SET f.position = e.position WHERE f.entity_id = ', @copilot),
  'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_3') > 0
             AND @copilot IS NOT NULL,
  CONCAT('UPDATE catalog_category_flat_store_3 f JOIN catalog_category_entity e ON e.entity_id = f.entity_id SET f.position = e.position WHERE f.entity_id = ', @copilot),
  'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
