-- 1216: (a) Three-paragraph "What's This Course About" for C20
-- "Build One Person Company with Multi AI Agents"; (b) create the missing
-- Funding Options block for C349 "Multi AI Agents System for Digital
-- Marketing", recommending a relevant WSQ course.
--
-- C20 is 7.5h / 1 day (Beginner) — the copy reflects that, matching the
-- house style used by C1164 (premise + named agent roles -> hands-on build
-- -> outcome and who it is for).
--
-- C20 already has course_C20_funding_and_grant pointing at
-- "WSQ - Build a Human-AI Workforce with Autonomous AI Agents" (verified
-- 200), so it is left alone. C349 has NO funding block, so one is created
-- in the same shape, pointing at "WSQ - Agentic AI for Digital Marketing"
-- (verified 200) — the closest WSQ course by subject.
--
-- cms_block is written with plain SQL only: NEVER ->save() a cms/block model,
-- which wipes cms_block_store and 404s the block (see the ai-vibe-coding-series
-- skill). The store mapping row is inserted explicitly at store 0, matching
-- the sibling funding blocks.
--
-- SG-guarded; C-prefix SKUs and these block identifiers are SG-only
-- (partner no-op). Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_psdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @e20 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C20' LIMIT 1);

-- ---------------------------------------------------------------------------
-- (a) C20 overview — three paragraphs.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e20,
'<p>The one-person company is no longer a compromise. With a team of AI agents behind you, a solo founder, freelancer or consultant can cover the work that used to need a marketing hire, a sales assistant, a project coordinator and a bookkeeper &mdash; a research agent, a content agent, an outreach agent, a delivery agent and an admin agent, each with a clear job, all reporting to you. In this hands-on 1-day course, you will learn how to design that agent workforce and put it to work in your own business.</p><p>Through guided exercises, you will map your business into agent-sized jobs, build a working agent org chart, and wire up agents that find and qualify leads, draft proposals and content, move client work forward, and keep invoicing and reporting on track. You will also set the guardrails that matter when nobody else is checking &mdash; approval gates, quality reviews and safe handoffs between agents.</p><p>By the end of the course, you will leave with a running multi-agent setup and a 90-day rollout plan for your own solo operation &mdash; so you can take on more clients, ship faster and reclaim the hours currently lost to admin, without adding headcount. Ideal for solo founders, freelancers, consultants and small business owners who want to operate at the scale of a team of one.</p>'
FROM dual
WHERE @e20 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e20
  AND attribute_id = @a_psdesc
  AND store_id <> 0
  AND @e20 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- (b) C349 Funding Options block.
-- ---------------------------------------------------------------------------

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C349 Funding and Grant',
       'course_C349_funding_and_grant',
       '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-digital-marketing.html" title="WSQ - Agentic AI for Digital Marketing">WSQ - Agentic AI for Digital Marketing</a></span></p>',
       NOW(), NOW(), 1
FROM dual
WHERE @is_sg > 0
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM cms_block) b
    WHERE b.identifier = 'course_C349_funding_and_grant'
  );

-- Content-only refresh when the block already exists (idempotent re-run).
UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-digital-marketing.html" title="WSQ - Agentic AI for Digital Marketing">WSQ - Agentic AI for Digital Marketing</a></span></p>',
    is_active = 1
WHERE identifier = 'course_C349_funding_and_grant'
  AND @is_sg > 0;

-- Store mapping (store 0 = all stores), matching the sibling funding blocks.
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0
FROM (SELECT * FROM cms_block) b
WHERE b.identifier = 'course_C349_funding_and_grant'
  AND @is_sg > 0;
