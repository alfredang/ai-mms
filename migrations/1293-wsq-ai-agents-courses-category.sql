-- 1293: Add a "WSQ AI Agents Courses" catalog page under WSQ AI Courses (325),
-- by REPURPOSING the deactivated category 194 ("Speed Typing").
--
-- Why repurpose instead of INSERT: the request was explicitly to "activate one
-- of the deactivated category". 194 was chosen because it is inactive at
-- store 0 AND store 1, carries only two stale product rows (C687, C692), and
-- sits in a branch (Business & Soft Skills) nothing links to any more.
--
-- A repurpose only changes what you explicitly write, so this migration
-- overwrites ALL of the carried-over state, not just the name:
--   * name, url_key, url_path (+ the store-scoped url_path rows)
--   * description / meta_title / meta_description / meta_keywords
--     (the old Speed Typing copy would otherwise render under the new H1)
--   * parent_id + path + level (reparent 1/2/3/68 -> under 325)
--   * position, unique among the new siblings
--   * page_layout / display_mode / is_anchor to match sibling 196
--   * deletes the store-scoped is_active / include_in_menu = 0 overrides,
--     which would otherwise shadow the new store-0 value and keep the page
--     dead + out of the menu
--   * clears the two stale product rows so the page shows only AI Agents
--
-- Placement: appended as position 5 under WSQ AI Courses, after the order set
-- by 1292 (1 Generative AI, 2 Agentic AI, 3 Programming & Vibe Coding,
-- 4 AI Ethics and Governance).
--
-- Membership: the 16 funded (TGS-) courses listed on the AI Agents Series page
-- (category 415) — WSQ, CASL and IBF alike — pinned in that page's curated
-- order. The 12 C-prefix courses on the series page are deliberately NOT
-- copied: this is a WSQ/funded category, matching its four siblings, all of
-- which are all-TGS. Because the category is all-TGS the funded-first rule
-- cannot be violated here.
--
-- umm_dd_type is left at '0' (inherit) — this is a level-4 category and must
-- never be set to Classic at level <= 3; 0 matches all four siblings.
--
-- Business-key lookups only (url_key / SKU). Idempotent.

SET @uk := (SELECT attribute_id FROM eav_attribute
            WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1);

-- The category being repurposed, resolved by its OLD slug so a re-run is a
-- no-op (after the first run the slug is the new one and @cat is NULL, which
-- makes every statement below match zero rows).
SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @uk AND value = 'speed-typing-courses-in' LIMIT 1);
-- On a re-run, fall back to the new slug so the pins/membership stay enforced.
SET @cat := COALESCE(@cat, (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @uk AND value = 'wsq-ai-agents-courses' LIMIT 1));

SET @parent := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'name'
  WHERE v.store_id = 0 AND v.value = 'WSQ AI Courses' LIMIT 1);

-- ---------------------------------------------------------------- structure
UPDATE catalog_category_entity c
JOIN catalog_category_entity p ON p.entity_id = @parent
SET c.parent_id = @parent,
    c.path      = CONCAT(p.path, '/', c.entity_id),
    c.level     = p.level + 1,
    c.position  = 5
WHERE c.entity_id = @cat AND @cat IS NOT NULL AND @parent IS NOT NULL;

-- ------------------------------------------------------------ varchar attrs
DROP TEMPORARY TABLE IF EXISTS tmp_cat_varchar;
CREATE TEMPORARY TABLE tmp_cat_varchar (code VARCHAR(64) PRIMARY KEY, val TEXT);
INSERT INTO tmp_cat_varchar (code, val) VALUES
  ('name',        'WSQ AI Agents Courses'),
  ('url_key',     'wsq-ai-agents-courses'),
  ('url_path',    'wsq-ai-agents-courses.html'),
  ('meta_title',  'WSQ AI Agents Courses - Build and Deploy AI Agents | Tertiary Courses Singapore'),
  ('display_mode','PRODUCTS'),
  ('page_layout', 'two_columns_left'),
  ('umm_dd_type', '0');

-- Drop store-scoped overrides first so the store-0 value wins everywhere.
DELETE v FROM catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3
JOIN tmp_cat_varchar t ON t.code = a.attribute_code
WHERE v.entity_id = @cat AND @cat IS NOT NULL AND v.store_id <> 0;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, t.val
FROM tmp_cat_varchar t
JOIN eav_attribute a ON a.entity_type_id = 3 AND a.attribute_code = t.code
WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------------ text attrs
DROP TEMPORARY TABLE IF EXISTS tmp_cat_text;
CREATE TEMPORARY TABLE tmp_cat_text (code VARCHAR(64) PRIMARY KEY, val TEXT);

INSERT INTO tmp_cat_text (code, val) VALUES
('description',
'<p>AI agents are the next step beyond chatbots and one-off prompts. An AI agent can reason over a goal, plan the steps needed to reach it, call tools and APIs, read and write to your systems, and keep working through a task with limited human supervision. Organisations in Singapore are moving quickly from experimenting with generative AI to deploying agents that handle real work - qualifying leads, resolving support tickets, monitoring security events, reconciling records and drafting deliverables.</p>
<p>Our WSQ AI Agents Courses are designed for professionals who need to build, deploy, govern and manage these systems in production. The curriculum spans the full stack: single-agent fundamentals, multi-agent workflows where specialised agents collaborate, the major agent development kits (OpenAI Agents SDK, Gemini Agent ADK, Hermes Agent, OpenClaw, Paperclip), and the operational disciplines that decide whether an agent deployment succeeds - harness and loop engineering, agent cybersecurity, and security operations for autonomous agents.</p>
<p>Business-focused courses complete the picture. If your responsibility is deciding <em>where</em> agents create value rather than writing the code, courses on AI Agents for Business, Business Innovation with Agentic AI, Business Transformation with Agentic AI and building a human-AI workforce cover use-case identification, workflow redesign, ROI, change management and the governance guardrails an agentic operating model needs.</p>
<h3>What you will learn</h3>
<ul>
<li>How AI agents plan, reason, use tools and maintain memory, and where they beat a plain LLM prompt</li>
<li>Building single and multi-agent systems with leading agent development kits and frameworks</li>
<li>Orchestrating multi-agent workflows in which specialised agents hand off work to each other</li>
<li>Harness and loop engineering - controlling agent execution loops, context and cost in production</li>
<li>Securing agents: prompt injection, tool-permission control, agent cybersecurity and security operations</li>
<li>Identifying high-value agentic use cases and redesigning business workflows around a human-AI workforce</li>
</ul>
<h3>Who should attend</h3>
<p>Developers, data and AI engineers, IT and security professionals, product and operations managers, business analysts, and leaders responsible for AI adoption. Courses range from business-level to hands-on technical, so participants can start at the level that fits their role.</p>
<h3>Funding</h3>
<p>These are WSQ, CASL and IBF funded courses. Eligible Singaporeans and PRs can enjoy SkillsFuture funding subsidies, and SkillsFuture Credit may be used to offset the nett course fee. Company-sponsored participants may also be eligible for SkillsFuture Enterprise Credit (SFEC) and absentee payroll. Please refer to each course page for the funding schemes that apply to that course.</p>'),

('meta_description',
'WSQ AI Agents Courses in Singapore. Learn to build, deploy, secure and manage single and multi-agent AI systems with OpenAI, Gemini, Hermes, OpenClaw and Paperclip. SkillsFuture funded, up to 70% subsidy.'),

('meta_keywords',
'WSQ AI agents course Singapore, AI agents training, autonomous AI agents, multi agent systems, agentic AI course, AI agent development, OpenAI Agents SDK training, Gemini Agent ADK course, AI agent cybersecurity, AI agent security operations, harness and loop engineering, AI agents for business, business transformation with AI agents, human AI workforce, CASL AI agents, IBF AI course, SkillsFuture AI agents, WSQ funded AI training, AI agent governance, build AI agents Singapore');

DELETE t FROM catalog_category_entity_text t
JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = 3
JOIN tmp_cat_text x ON x.code = a.attribute_code
WHERE t.entity_id = @cat AND @cat IS NOT NULL AND t.store_id <> 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, x.val
FROM tmp_cat_text x
JOIN eav_attribute a ON a.entity_type_id = 3 AND a.attribute_code = x.code
WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------------- int attrs
DROP TEMPORARY TABLE IF EXISTS tmp_cat_int;
CREATE TEMPORARY TABLE tmp_cat_int (code VARCHAR(64) PRIMARY KEY, val INT);
INSERT INTO tmp_cat_int (code, val) VALUES
  ('is_active', 1),
  ('include_in_menu', 1),
  ('is_anchor', 1),
  ('custom_use_parent_settings', 0),
  ('custom_apply_to_products', 0);

-- The store-1 is_active=0 / include_in_menu=0 overrides MUST go, or the page
-- stays dead and out of the menu no matter what store 0 says.
DELETE i FROM catalog_category_entity_int i
JOIN eav_attribute a ON a.attribute_id = i.attribute_id AND a.entity_type_id = 3
JOIN tmp_cat_int t ON t.code = a.attribute_code
WHERE i.entity_id = @cat AND @cat IS NOT NULL AND i.store_id <> 0;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, t.val
FROM tmp_cat_int t
JOIN eav_attribute a ON a.entity_type_id = 3 AND a.attribute_code = t.code
WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- --------------------------------------------------------------- products
-- Clear the two stale Speed Typing rows.
DELETE FROM catalog_category_product WHERE category_id = @cat AND @cat IS NOT NULL;
DELETE FROM catalog_category_product_index WHERE category_id = @cat AND @cat IS NOT NULL;

-- The 16 funded courses from the AI Agents Series page, in that page's order.
DROP TEMPORARY TABLE IF EXISTS tmp_agents;
CREATE TEMPORARY TABLE tmp_agents (sku VARCHAR(64) PRIMARY KEY, pos INT);
INSERT INTO tmp_agents (sku, pos) VALUES
  ('TGS-2025054471',  1),  -- WSQ - Autonomous AI Agents
  ('TGS-2020503395',  2),  -- WSQ - Business Innovation with AI Agents
  ('TGS-2023018987',  3),  -- WSQ - AI Agents for Business
  ('TGS-2026064176',  4),  -- CASL - AI Agent with Hermes Agent
  ('TGS-2026064859',  5),  -- CASL - Autonomous AI Agents with OpenClaw
  ('TGS-2023036646',  6),  -- WSQ - Manage AI Agents with Paperclip
  ('TGS-2023036153',  7),  -- WSQ - Multi AI Agents Workflow for Content Creation
  ('TGS-2024043854',  8),  -- WSQ - Build a Human-AI Workforce with Autonomous AI Agents
  ('TGS-2025053228',  9),  -- WSQ - AI Agent Cybersecurity
  ('TGS-2024042604', 10),  -- WSQ - Security Operations for Autonomous AI Agents
  ('TGS-2024049182', 11),  -- WSQ - Business Transformation with Agentic AI and AI Agents
  ('TGS-2026064173', 12),  -- CASL - AI Agents with Gemini Spark
  ('TGS-2024042961', 13),  -- WSQ - Develop Multi AI Agent Applications with Gemini Agent ADK
  ('TGS-2021010367', 14),  -- WSQ - Harness and Loop Engineering for AI Agents
  ('TGS-2024042309', 15),  -- WSQ - Develop AI Agents with OpenAI Agent Development Kit
  ('TGS-2023037472', 16);  -- WSQ - Business Innovation with Agentic AI and AI Agents

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, p.entity_id, t.pos
FROM tmp_agents t
JOIN catalog_product_entity p ON p.sku = t.sku
WHERE @cat IS NOT NULL
ON DUPLICATE KEY UPDATE position = VALUES(position);

INSERT INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, p.entity_id, t.pos, 1, s.store_id, MAX(i.visibility)
FROM tmp_agents t
JOIN catalog_product_entity p ON p.sku = t.sku
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @cat IS NOT NULL
GROUP BY p.entity_id, s.store_id, t.pos
ON DUPLICATE KEY UPDATE position = VALUES(position);

-- ---------------------------------------------------------------- rewrites
-- Retire the old Speed Typing rewrite rows for this category and let the
-- Catalog URL Rewrites reindex regenerate them for the new slug.
DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('category/', @cat) AND @cat IS NOT NULL;
