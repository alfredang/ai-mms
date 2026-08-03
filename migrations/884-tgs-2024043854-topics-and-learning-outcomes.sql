-- 884: TGS-2024043854 "Build a Human–AI Workforce with Autonomous AI Agents"
--
--  1. Rewrite "What You'll Learn" (product description) to the 3 new topics —
--     Hermes Agent / OpenClaw / Paperclip — matching the About-This-Course
--     narrative that already names those three tools. Keeps the LSN_DATA JSON
--     marker in sync with the rendered HTML so the admin developer Lesson view
--     and the storefront card agree.
--  2. Seed the per-course Learning Outcomes cms_block
--     (identifier convention: course_<sku>_learning_outcomes) so the storefront
--     "Learning Outcomes" card renders — there was no such block for this SKU,
--     and short_description carries no <h2>Learning Outcomes</h2> for the
--     regex fallback to pick up, so the card was hidden entirely.
--
-- SG-only by construction: TGS- SKUs exist on the SG site; on MY/GH the
-- entity lookup yields NULL and every statement is a guarded no-op.
-- Idempotent: description is set (not appended); the cms_block is
-- INSERT ... ON DUPLICATE KEY UPDATE on the unique identifier.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024043854' LIMIT 1);

SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product' LIMIT 1);
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @et AND attribute_code = 'description' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1. What You'll Learn — three topics, no sub-sections.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text SET value = CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: LLM Applications with Hermes Agent","subsecs":[]},{"title":"Topic 2: RAG and Context Engineering with OpenClaw","subsecs":[]},{"title":"Topic 3: Multi-Agent Management with Paperclip","subsecs":[]}] -->', '\n',
'<p><strong>Topic 1: LLM Applications with Hermes Agent</strong></p>', '\n',
'<p><strong>Topic 2: RAG and Context Engineering with OpenClaw</strong></p>', '\n',
'<p><strong>Topic 3: Multi-Agent Management with Paperclip</strong></p>')
  WHERE @e IS NOT NULL AND @a_desc IS NOT NULL
    AND entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- ---------------------------------------------------------------------------
-- 2. Learning Outcomes cms_block (create if missing, else overwrite content).
-- ---------------------------------------------------------------------------
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT
  'Course TGS-2024043854 — Learning Outcomes',
  'course_TGS-2024043854_learning_outcomes',
  CONCAT(
    '<p>By end of the course, learners should be able to:</p>', '\n',
    '<ul>', '\n',
    '<li>LO1: Analyze LLM applications across a range of industries to identify their capabilities and limitations.</li>', '\n',
    '<li>LO2: Establish the relationship between LLM design and Chatbot efficiency.</li>', '\n',
    '<li>LO3: Evaluate and improve RAG application effectiveness in product.</li>', '\n',
    '</ul>'),
  NOW(), NOW(), 1
FROM DUAL
WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE
  content = VALUES(content),
  is_active = 1,
  update_time = NOW();

-- Store mapping: all-store-views (store_id = 0), matching the sibling
-- course_TGS-2024043854_brochure block. Separate statement because a
-- cms_block INSERT does not populate cms_block_store.
SET @b := (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2024043854_learning_outcomes' LIMIT 1);

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT @b, 0 FROM DUAL WHERE @b IS NOT NULL;
