-- 1219: Let the AI Applications Series submenu size to its content.
--
-- The flyout rendered with an inline style="width:1000px;" — far wider than
-- its ten short links — because category 139 still carries the Infortis
-- mega-menu attributes umm_dd_width = '1000px' and umm_dd_columns = 2 from
-- an earlier configuration, when the category drove a wide multi-column
-- panel. Every sibling series (Generative AI, Agentic AI, AI Agents,
-- Microsoft Copilot, AI Vibe Coding, ...) has both attributes NULL and gets
-- the theme default (.nav-regular .classic > .nav-panel--dropdown
-- { width: 16em; min-width: 12em; }), which sizes to the links.
--
-- Clearing the two attributes drops the inline width so the submenu matches
-- its siblings. The horizontal offset that made the flyout overlap the
-- parent menu is a THEME issue, fixed alongside this in
-- skin/frontend/ultimo/default/css/custom.css (Ultimo positions nested
-- dropdowns at left:60px, which overlaps the parent column).
--
-- Menu HTML is cached (setCacheLifetime 3600) and umm_dd_* live in the flat
-- category tables, so a flat reindex + cache flush is required after this —
-- both are part of the deploy/apply routine.
--
-- SG-guarded; resolved by url_key (partner no-op). Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_ddwidth := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'umm_dd_width');
SET @a_ddcols  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'umm_dd_columns');

SET @apps := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0
    AND v.value = 'ai-applications-series' LIMIT 1
);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @apps
  AND attribute_id = @a_ddwidth
  AND @apps IS NOT NULL AND @is_sg > 0;

DELETE FROM catalog_category_entity_int
WHERE entity_id = @apps
  AND attribute_id = @a_ddcols
  AND @apps IS NOT NULL AND @is_sg > 0;

-- Flat mirror (store 1), guarded; 'DO 0' no-op.
SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
);

SET @has_cols := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
    AND COLUMN_NAME IN ('umm_dd_width', 'umm_dd_columns')
);

SET @sql := IF(@has_flat > 0 AND @has_cols = 2 AND @apps IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET umm_dd_width = NULL, umm_dd_columns = NULL WHERE entity_id = @apps',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;
