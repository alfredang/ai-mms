-- Rename C1034: "Multi AI Agents with Autogen" (migration 525)
--            -> "Multi Agents System with Autogen"
-- SLUG CHANGE: url_key orchestrate-multi-ai-agents-with-autogen
--           -> multi-agents-system-with-autogen
-- Rebrands name, meta title/description/keywords, image labels, gallery label,
-- and cover, AND changes the storefront slug. The curriculum (description),
-- price and duration are unchanged.
--
-- Cover re-rendered 2026-07-18 from the new title (no funding chips - C1034
-- carries no funding-badge tags) and uploaded to R2.
--
-- Slug-change handling (this is why it differs from every prior text-only
-- rename): stale url_path rows are DELETED so the Catalog-URL-Rewrites indexer
-- regenerates the new product/1035/* system rewrites at the new slug. The old
-- bare system rewrite is deleted (indexer recreates it). A 301 (RP) is inserted
-- from the old bare path to the new one so existing links don't 404, and every
-- pre-existing is_system=0 RP row that TARGETED the old path is repointed at the
-- new path so no redirect dead-ends.
--
-- AFTER DEPLOY ON SG PROD you MUST run the reindex API (Catalog URL Rewrites +
-- Product/Category Flat) so the new slug's system rewrites materialise:
--   GET /reindex/api/run?token=...&flush=1
-- Until reindex runs, the storefront may still serve the old slug from flat/FPC.
--
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C1034.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1034');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

-- Title + meta
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Multi Agents System with Autogen' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Multi Agents System with AutoGen &mdash; Master RAG, AgentChat &amp; Multi-Agent Workflows | Tertiary Courses Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Learn to build a multi agents system with AutoGen. Master AgentChat, RAG, and multi-agent workflows to automate tasks and build scalable AI solutions.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'multi agents system, AutoGen course, AutoGen AgentChat, multi-agent AI workflow, Retrieval-Augmented Generation, RAG agent, AI agents training, CrewAI, LLM models, multi-agent systems, AI automation, AutoGen tutorial, build AI agents, AI workflow automation, multi-agent collaboration, RAG AI course, AI agent development, generative AI training, agentic AI, AutoGen multi-agent' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-18
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1034-20260717-184532.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Multi Agents System with Autogen' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Multi Agents System with Autogen' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Multi Agents System with Autogen' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Product-page zoom gallery renders the per-image gallery label, not the EAV labels
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Multi Agents System with Autogen'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- --- SLUG CHANGE ---
-- New url_key at store 0.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_uk, 0, @e, 'multi-agents-system-with-autogen' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop stale url_path (all stores) so the URL-rewrite indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up;

-- Delete the old bare system rewrite; the indexer recreates system rows at the
-- new slug. Category-scoped system rows (product/1035/N) are also regenerated.
DELETE FROM core_url_rewrite
WHERE product_id=@e AND @e IS NOT NULL AND is_system=1;

-- 301 from the old bare path to the new one (skip if one already exists).
INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e, CONCAT('c1034-slug-301-', @e), 'orchestrate-multi-ai-agents-with-autogen.html', 'multi-agents-system-with-autogen.html', 0, 'RP', 'C1034 slug rename 301'
FROM DUAL
WHERE @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path='orchestrate-multi-ai-agents-with-autogen.html'
  );

-- Repoint every pre-existing is_system=0 RP row that TARGETED the old bare path
-- so historical redirect chains land on the new slug, not a 404.
UPDATE core_url_rewrite
SET target_path = 'multi-agents-system-with-autogen.html'
WHERE @e IS NOT NULL AND is_system=0 AND target_path='orchestrate-multi-ai-agents-with-autogen.html';

-- ...and the category-prefixed variants (adult-training-courses/... etc.).
UPDATE core_url_rewrite
SET target_path = REPLACE(target_path, 'orchestrate-multi-ai-agents-with-autogen.html', 'multi-agents-system-with-autogen.html')
WHERE @e IS NOT NULL AND is_system=0 AND target_path LIKE '%/orchestrate-multi-ai-agents-with-autogen.html';

-- Clear per-store overrides so partner scopes can't shadow store 0.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_il, @a_sil, @a_til, @a_ciu, @a_uk);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_mk);
