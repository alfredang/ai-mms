-- 1205: Show the AI Applications Series subcategories in the AI Courses
-- mega-menu dropdown (a flyout under "AI Applications Series").
--
-- The subcategories created/repurposed by 1196 and 1204 were given
-- include_in_menu = 0, matching the older hidden children (Computer Vision /
-- Reinforcement Learning). With that flag off the parent renders as a
-- "classic" menu item with no submenu. Setting it to 1 on the parent's
-- children makes Infortis UltraMegamenu render the third level;
-- catalog/navigation/max_depth is 0 (unlimited) and category 139 already
-- carries its umm_dd_* dropdown settings, so no config change is needed.
--
-- Scope: only the direct children of the AI Applications Series, resolved by
-- the parent's url_key. Computer Vision and Reinforcement Learning (RL) are
-- included too — they are members of the same dropdown and were only hidden
-- by the same default.
--
-- Store-level overrides are cleared so the store-0 value wins. SG-only
-- url_key (clean partner no-op). Idempotent.

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_cmenu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');

SET @apps := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'ai-applications-series' LIMIT 1
);

DELETE cei FROM catalog_category_entity_int cei
JOIN catalog_category_entity e ON e.entity_id = cei.entity_id
WHERE cei.attribute_id = @a_cmenu
  AND cei.store_id <> 0
  AND e.parent_id = @apps
  AND @apps IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, e.entity_id, 1
FROM catalog_category_entity e
WHERE e.parent_id = @apps
  AND @apps IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flat mirror (store 1), guarded; 'DO 0' no-op.
SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
);

SET @sql := IF(@has_flat > 0 AND @apps IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET include_in_menu = 1 WHERE parent_id = @apps',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;
