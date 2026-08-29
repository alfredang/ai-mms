-- 1187: Create the "Microsoft Copilot Series" category by repurposing the
-- deactivated, empty "Microsoft Outlook" category (0 products, 0 children):
--   - rename to "Microsoft Copilot Series", url_key microsoft-copilot-series
--   - move under the AI Series parent, positioned right after AI Agents Series
--   - activate + include in menu
--   - attach the three WSQ Copilot courses moved out of Generative AI Series
--     by migration 1186:
--       TGS-2024043856  WSQ - Enhance Work Productivity with Microsoft 365 Copilot
--       TGS-2022017524  WSQ - Business Process Automation with Power Automate and Copilot Studio Agents
--       TGS-2023036648  WSQ - Create Intelligent Power Apps and Power Automate Workflows with Copilot
--
-- SG-ONLY: guarded on the SG base_url so partner instances (MY/GH) never
-- touch their own category trees. Idempotent: after the first run the
-- category resolves by its NEW url_key and every write is a no-op/upsert.
-- Reparent rule: NEVER write url_key to match the parent path —
-- MMD_FlatCategoryUrl keeps every category at /<url_key>.html.
-- Post-apply: Category Flat Data + Catalog URL reindex, then cache flush
-- (the live-apply run hits the reindex API; a rebuilt DB gets it from the
-- guarded flat mirror below plus the scheduled nightly reindex).

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @cat := IF(@is_sg > 0, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'microsoft-outlook-courses' LIMIT 1)
), NULL);

-- AI Series parent = parent of the AI Agents Series category.
SET @agents := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-agents-series' LIMIT 1
);
SET @parent := (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @agents);
SET @parentpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @parent);
SET @newpos := (SELECT position + 1 FROM catalog_category_entity WHERE entity_id = @agents);

SET @oldparent := (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @cat);
SET @oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @cat);
SET @needs_move := IF(@cat IS NOT NULL AND @parent IS NOT NULL AND @oldparent <> @parent, 1, 0);

-- Attribute ids.
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_path');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_menu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');
SET @a_metatitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');
SET @a_layout := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'page_layout');

-- ---------------------------------------------------------------------------
-- 1) Tree move: make room after AI Agents Series, then reparent.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_entity
SET position = position + 1
WHERE @needs_move = 1
  AND parent_id = @parent
  AND position >= @newpos
  AND entity_id <> @cat;

-- Recursive children_count: -1 on old ancestors not shared with the new path,
-- +1 on new ancestors not shared with the old path (root/base cancel out).
UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','))
  AND entity_id <> @cat
  AND NOT FIND_IN_SET(entity_id, REPLACE(@parentpath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @needs_move = 1
  AND FIND_IN_SET(entity_id, REPLACE(@parentpath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @parent,
    path = CONCAT(@parentpath, '/', entity_id),
    level = (LENGTH(@parentpath) - LENGTH(REPLACE(@parentpath, '/', ''))) + 1,
    position = @newpos
WHERE @needs_move = 1
  AND entity_id = @cat;

-- ---------------------------------------------------------------------------
-- 2) Attributes: rename, re-slug, activate, show in menu.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_name, 0, @cat, 'Microsoft Copilot Series'
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_urlkey, 0, @cat, 'microsoft-copilot-series'
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flat URLs: every existing url_path row (store 0 + store overrides) follows.
UPDATE catalog_category_entity_varchar
SET value = 'microsoft-copilot-series.html'
WHERE entity_id = @cat
  AND attribute_id = @a_urlpath
  AND @cat IS NOT NULL;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metatitle, 0, @cat, 'Microsoft Copilot Series'
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop store-level overrides so the store-0 values below win everywhere.
DELETE FROM catalog_category_entity_int
WHERE entity_id = @cat
  AND attribute_id IN (@a_active, @a_menu)
  AND store_id <> 0
  AND @cat IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_active, 0, @cat, 1
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_menu, 0, @cat, 1
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- The other Series categories inherit the default page layout; drop the old
-- two_columns_left override so this one matches them.
DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @cat
  AND attribute_id = @a_layout
  AND @cat IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3) Attach the three WSQ Copilot courses (base + index mirror).
--    Position 9999 = end of list; the nightly ordering sweep renumbers.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @cat IS NOT NULL
  AND p.sku IN ('TGS-2024043856', 'TGS-2022017524', 'TGS-2023036648');

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @cat IS NOT NULL
  AND p.sku IN ('TGS-2024043856', 'TGS-2022017524', 'TGS-2023036648')
GROUP BY p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 4) Guarded flat mirror (store 1 = the active SG store view) so the change
--    renders without waiting for a reindex. information_schema-guarded;
--    'DO 0' no-op (never 'SELECT 1' — apply.php PDO trap).
-- ---------------------------------------------------------------------------

SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
);

SET @sql := IF(@has_flat > 0 AND @cat IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET position = position + 1 WHERE @needs_move = 1 AND parent_id = @parent AND position >= @newpos AND entity_id <> @cat',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;

SET @sql := IF(@has_flat > 0 AND @cat IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET parent_id = @parent, path = CONCAT(@parentpath, ''/'', entity_id), level = (LENGTH(@parentpath) - LENGTH(REPLACE(@parentpath, ''/'', ''''))) + 1, position = @newpos, is_active = 1, include_in_menu = 1, name = ''Microsoft Copilot Series'', url_key = ''microsoft-copilot-series'', url_path = ''microsoft-copilot-series.html'' WHERE entity_id = @cat',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;
