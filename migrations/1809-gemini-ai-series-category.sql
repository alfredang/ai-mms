-- 1809: Create the "Gemini AI Series" category by repurposing the deactivated,
-- childless "Google Sheets" category (url_key google-sheets-training-retired):
--   - rename to "Gemini AI Series", url_key gemini-ai-series
--   - move under AI Courses (252), positioned right after Microsoft Copilot Series
--   - activate + include in menu; new description / meta (the old Google Sheets
--     copy would otherwise carry over), store-scoped overrides dropped
--   - membership: replace the one leftover course (TGS-2024049213 Google Sheets &
--     Looker Studio, not a Gemini course) with every live Gemini course, funded
--     first then non-WSQ A-Z (the nightly ordering sweep keeps this order):
--       1 TGS-2024042961  WSQ - Develop Multi AI Agent Applications with Gemini Agent ADK
--       2 TGS-2026064173  CASL - AI Agents with Gemini Spark
--       3 C1259           AI Agents with Gemini Spark
--       4 C829            Building Multi Agent Aplications with Gemini ADK
--       5 C817            Gemini for Google Sheet
--   - the category's own system rewrite is renamed in place to gemini-ai-series.html;
--     the removed course's category-prefixed rewrite (and the 301s landing on it)
--     are pointed at that course's own flat URL so nothing 404s after reindex.
--
-- SG-ONLY: guarded on the SG base_url (partner category ids differ). Idempotent:
-- after the first run the category resolves by its NEW url_key.
-- Post-apply: Category Flat Data + Catalog URL reindex, then cache flush.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @cat := IF(@is_sg > 0, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'gemini-ai-series' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id
    AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
   WHERE v.store_id = 0 AND v.value = 'google-sheets-training-retired' LIMIT 1)
), NULL);

-- AI Courses parent = parent of Microsoft Copilot Series; new slot right after it.
SET @copilot := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1
);
SET @parent := (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @copilot);
SET @parentpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @parent);
SET @newpos := (SELECT position + 1 FROM catalog_category_entity WHERE entity_id = @copilot);

SET @oldparent := (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @cat);
SET @oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @cat);
SET @needs_move := IF(@cat IS NOT NULL AND @parent IS NOT NULL AND @oldparent <> @parent, 1, 0);

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_path');
SET @a_active := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_menu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');
SET @a_metatitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');
SET @a_metadesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description');
SET @a_metakey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_keywords');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');
SET @a_layout := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'page_layout');

-- ---------------------------------------------------------------------------
-- 1) Tree move: make room after Microsoft Copilot Series, then reparent.
-- ---------------------------------------------------------------------------

UPDATE catalog_category_entity
SET position = position + 1
WHERE @needs_move = 1
  AND parent_id = @parent
  AND position >= @newpos
  AND entity_id <> @cat;

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
-- 2) Attributes: rename, re-slug, activate, menu, fresh copy.
-- ---------------------------------------------------------------------------

DELETE FROM catalog_category_entity_varchar
WHERE @cat IS NOT NULL AND entity_id = @cat AND store_id <> 0
  AND attribute_id IN (@a_name, @a_urlkey, @a_metatitle);

DELETE FROM catalog_category_entity_text
WHERE @cat IS NOT NULL AND entity_id = @cat AND store_id <> 0
  AND attribute_id IN (@a_desc, @a_metadesc, @a_metakey);

DELETE FROM catalog_category_entity_int
WHERE @cat IS NOT NULL AND entity_id = @cat AND store_id <> 0
  AND attribute_id IN (@a_active, @a_menu);

-- Siblings inherit the default layout; drop the old two_columns_left override.
DELETE FROM catalog_category_entity_varchar
WHERE @cat IS NOT NULL AND entity_id = @cat AND attribute_id = @a_layout;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_name, 0, @cat, 'Gemini AI Series'
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_urlkey, 0, @cat, 'gemini-ai-series'
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'gemini-ai-series.html'
WHERE @cat IS NOT NULL AND entity_id = @cat AND attribute_id = @a_urlpath;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metatitle, 0, @cat, 'Gemini AI Courses &ndash; Gemini ADK, Agents &amp; Google Sheets'
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_desc, 0, @cat, '<p>Gemini is Google&rsquo;s family of AI models, built into Google Workspace and available to developers through the Gemini API and the Agent Development Kit (ADK). It can write and explain spreadsheet formulas, analyse data in plain language, and power AI agents that plan, use tools and work together on real business tasks.</p><p>The Gemini AI Series takes you from everyday productivity to building agents. Learn to use Gemini inside Google Sheets to clean, analyse and chart your data; build AI agents with Gemini Spark; and develop multi-agent applications with the Gemini ADK. Funded WSQ and CASL courses are listed first, followed by our non-WSQ short courses.</p>'
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metadesc, 0, @cat, 'Hands-on Gemini AI courses in Singapore: use Gemini in Google Sheets, build AI agents with Gemini Spark and develop multi-agent applications with the Gemini ADK.'
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metakey, 0, @cat, 'Gemini, Google Gemini, Gemini AI course, Gemini ADK, Agent Development Kit, Gemini Spark, Gemini for Google Sheets, AI agents, multi-agent applications, Singapore'
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_active, 0, @cat, 1
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_menu, 0, @cat, 1
FROM dual WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 3) Membership: drop non-Gemini leftovers, add the Gemini courses at 1..5
--    (base + index mirror).
-- ---------------------------------------------------------------------------

DROP TEMPORARY TABLE IF EXISTS tmp_gemini_series;
CREATE TEMPORARY TABLE tmp_gemini_series (sku VARCHAR(64) PRIMARY KEY, pos INT);
INSERT INTO tmp_gemini_series VALUES
  ('TGS-2024042961', 1),
  ('TGS-2026064173', 2),
  ('C1259', 3),
  ('C829', 4),
  ('C817', 5);

DROP TEMPORARY TABLE IF EXISTS tmp_gemini_pid;
CREATE TEMPORARY TABLE tmp_gemini_pid (product_id INT PRIMARY KEY, pos INT);
INSERT INTO tmp_gemini_pid
SELECT p.entity_id, t.pos
FROM catalog_product_entity p
JOIN tmp_gemini_series t ON t.sku = TRIM(p.sku)
WHERE @cat IS NOT NULL;

DELETE cp FROM catalog_category_product cp
LEFT JOIN tmp_gemini_pid g ON g.product_id = cp.product_id
WHERE @cat IS NOT NULL AND cp.category_id = @cat AND g.product_id IS NULL;

DELETE ci FROM catalog_category_product_index ci
LEFT JOIN tmp_gemini_pid g ON g.product_id = ci.product_id
WHERE @cat IS NOT NULL AND ci.category_id = @cat AND g.product_id IS NULL;

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, g.product_id, g.pos FROM tmp_gemini_pid g
ON DUPLICATE KEY UPDATE position = VALUES(position);

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, g.product_id, g.pos, 1, s.store_id, 4
FROM tmp_gemini_pid g
JOIN core_store s ON s.store_id > 0
ON DUPLICATE KEY UPDATE position = VALUES(position), is_parent = 1;

DROP TEMPORARY TABLE IF EXISTS tmp_gemini_pid;
DROP TEMPORARY TABLE IF EXISTS tmp_gemini_series;

-- ---------------------------------------------------------------------------
-- 4) Rewrites.
-- ---------------------------------------------------------------------------

-- Category's own system row: rename in place (no new 301 rung).
UPDATE core_url_rewrite
SET request_path = 'gemini-ai-series.html'
WHERE @cat IS NOT NULL AND store_id = 1 AND is_system = 1
  AND product_id IS NULL AND category_id = @cat
  AND request_path = 'google-sheets-training-retired.html';

-- Removed course: its category-prefixed rows (and 301s landing on them) go to
-- the course's own flat URL. They are DETACHED from the category/product pair
-- (category_id/product_id NULL, own id_path): the Catalog URL reindex deletes
-- every row still tagged with a category membership that no longer exists.
SET @old_prod_path := 'google-sheets-training-retired/wsq-enhance-data-insights-with-google-sheets-and-looker-studio.html';
SET @prod_path := 'wsq-enhance-data-insights-with-google-sheets-and-looker-studio.html';

UPDATE core_url_rewrite
SET target_path = @prod_path, category_id = NULL, product_id = NULL
WHERE @cat IS NOT NULL AND options = 'RP' AND target_path = @old_prod_path;

UPDATE core_url_rewrite
SET target_path = @prod_path, is_system = 0, options = 'RP',
    category_id = NULL, product_id = NULL,
    id_path = CONCAT('mmd-gemini-series-301-', MD5(request_path))
WHERE @cat IS NOT NULL AND request_path = @old_prod_path AND is_system = 1;

-- ---------------------------------------------------------------------------
-- 5) Guarded flat mirror (store 1) so it renders before the reindex.
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
  'UPDATE catalog_category_flat_store_1 SET parent_id = @parent, path = CONCAT(@parentpath, ''/'', entity_id), level = (LENGTH(@parentpath) - LENGTH(REPLACE(@parentpath, ''/'', ''''))) + 1, position = @newpos, is_active = 1, include_in_menu = 1, name = ''Gemini AI Series'', url_key = ''gemini-ai-series'', url_path = ''gemini-ai-series.html'' WHERE entity_id = @cat',
  'DO 0');
PREPARE s FROM @sql;
EXECUTE s;
DEALLOCATE PREPARE s;
