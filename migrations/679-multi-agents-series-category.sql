-- 679: Convert "RAG & Fine Tuning" (url_key rag-fine-tunning-courses) into
-- "Multi Agents Series":
--   1. Reparent from Generative AI Series to directly under AI Courses,
--      positioned right after AI Vibe Coding Series (564 move pattern:
--      parent_id/path/level/position + both parents' children_count ONLY).
--   2. Rename to "Multi Agents Series"; url_key -> multi-agents-series with
--      the stale is_system rewrite converted to a surviving 301 (567 pattern).
--   3. Assign six WSQ multi-agent courses; remove them from AI Agents Series.
--
-- Categories resolved by url_key (ids differ per site). Products are TGS-
-- SKUs, absent on MY/GH => those statements no-op there; the category
-- move/rename applies everywhere to keep the tree in parity.
-- Flat tables are NOT written here (Option A): the post-deploy reindex
-- (catalog_category_flat + catalog_url) regenerates them.

SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_path');
SET @a_cname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_cmt  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');
SET @a_cmd  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description');
SET @a_cdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');

SET @cat  := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id = @a_uk AND store_id = 0 AND value IN ('rag-fine-tunning-courses', 'multi-agents-series') LIMIT 1);
SET @ai   := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id = @a_uk AND store_id = 0 AND value = 'artificial-intelligence-courses' LIMIT 1);
SET @vibe := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id = @a_uk AND store_id = 0 AND value = 'ai-vibe-coding-series' LIMIT 1);
SET @agents := (SELECT entity_id FROM catalog_category_entity_varchar WHERE attribute_id = @a_uk AND store_id = 0 AND value = 'ai-agents-series' LIMIT 1);

SET @oldparent := (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @cat);
SET @vibepos   := (SELECT position FROM catalog_category_entity WHERE entity_id = @vibe);
SET @needs_move := (SELECT COUNT(*) FROM catalog_category_entity WHERE entity_id = @cat AND parent_id <> @ai);

-- 1) Reparent + position after AI Vibe Coding Series (only when not already there)
UPDATE catalog_category_entity SET position = position + 1
  WHERE parent_id = @ai AND position > @vibepos AND entity_id <> @cat AND @needs_move = 1;
UPDATE catalog_category_entity
  SET parent_id = @ai,
      path      = CONCAT((SELECT p FROM (SELECT path p FROM catalog_category_entity WHERE entity_id = @ai) x), '/', entity_id),
      level     = (SELECT l FROM (SELECT level l FROM catalog_category_entity WHERE entity_id = @ai) y) + 1,
      position  = @vibepos + 1
  WHERE entity_id = @cat AND @needs_move = 1;
UPDATE catalog_category_entity SET children_count = (SELECT COUNT(*) FROM (SELECT entity_id FROM catalog_category_entity WHERE parent_id = @oldparent) a) WHERE entity_id = @oldparent AND @oldparent <> @ai;
UPDATE catalog_category_entity SET children_count = (SELECT COUNT(*) FROM (SELECT entity_id FROM catalog_category_entity WHERE parent_id = @ai) b) WHERE entity_id = @ai;

-- 2) Rename + new slug + topic-correct meta/description (store 0; drop store overrides)
UPDATE catalog_category_entity_varchar SET value = 'Multi Agents Series'
  WHERE entity_id = @cat AND attribute_id = @a_cname AND store_id = 0;
DELETE FROM catalog_category_entity_varchar WHERE entity_id = @cat AND attribute_id = @a_cname AND store_id <> 0;
UPDATE catalog_category_entity_varchar SET value = 'Multi Agents Series Courses'
  WHERE entity_id = @cat AND attribute_id = @a_cmt AND store_id = 0;
UPDATE catalog_category_entity_varchar SET value = 'Hands-on multi-agent AI courses: build, orchestrate, and deploy collaborative autonomous AI agents with OpenAI ADK, AutoGen, CrewAI, and Gemini ADK.'
  WHERE entity_id = @cat AND attribute_id = @a_cmd AND store_id = 0;
UPDATE catalog_category_entity_text SET value = '<p>The Multi Agents Series covers designing, building, and deploying multi-agent AI systems, where autonomous AI agents collaborate, use tools, and automate complex workflows using frameworks such as OpenAI Agent Development Kit, AutoGen, CrewAI, and Gemini Agent ADK.</p>'
  WHERE entity_id = @cat AND attribute_id = @a_cdesc AND store_id = 0;

UPDATE catalog_category_entity_varchar SET value = 'multi-agents-series'
  WHERE entity_id = @cat AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_category_entity_varchar WHERE entity_id = @cat AND attribute_id = @a_up;

-- Re-point any existing 301s at the old slug (avoid 301 chains), then convert
-- the stale is_system row for the old slug into a surviving 301 (567 pattern).
UPDATE core_url_rewrite SET target_path = 'multi-agents-series.html'
  WHERE product_id IS NULL AND options = 'RP' AND target_path = 'rag-fine-tunning-courses.html';
UPDATE core_url_rewrite
  SET target_path = 'multi-agents-series.html', is_system = 0, options = 'RP', description = 'slug 301 (679)'
  WHERE product_id IS NULL AND request_path = 'rag-fine-tunning-courses.html'
    AND target_path <> 'multi-agents-series.html';

-- 3) Course assignments (TGS- SKUs: SG-only, no-op on partners)
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
  SELECT @cat, e.entity_id, 1 FROM catalog_product_entity e
  WHERE e.sku IN ('TGS-2024042309', 'TGS-2025059028', 'TGS-2024042961',
                  'TGS-2024045806', 'TGS-2020503207', 'TGS-2024043854')
    AND @cat IS NOT NULL;

DELETE cp FROM catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id
  WHERE cp.category_id = @agents
    AND e.sku IN ('TGS-2024042309', 'TGS-2025059028', 'TGS-2024042961',
                  'TGS-2024045806', 'TGS-2020503207', 'TGS-2024043854');
