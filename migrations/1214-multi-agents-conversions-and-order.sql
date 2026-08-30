-- 1214: Multi AI Agents Series — two conversions, one rename, curated order.
--
-- A) Convert two non-WSQ courses (SKUs unchanged; new name, new url_key with
--    a 301, fresh branded R2 cover, rewritten "What This Course About"
--    (short_description) and "What You'll Learn" (description topics), new
--    meta):
--      C20  Manage Multi Agents with Paperclip
--             -> Build One Person Company with Multi AI Agents
--      C349 AI Vibe Coding for Multi Agent AI Systems
--             -> Multi AI Agents System for Digital Marketing
--    Both stay in the Multi AI Agents Series. C349 also stays in the AI Vibe
--    Coding Series and the AI Agents Series where it is currently listed.
--
-- B) Rename C1164 "Multi Agents System for Algorithmic Trading" ->
--    "Multi AI Agents System for Algorithmic Trading", with a new url_key
--    + 301 and a fresh cover. Content unchanged.
--
-- C) Pin the requested 7-course non-WSQ order at 101..107, after every
--    WSQ/CASL/IBF course, and add 'multi-agents-series' to
--    mmd/category_ordering/curated_url_keys so the sweep preserves it.
--
-- Topic HTML follows the LSN_DATA + <h3 class="course-topic-h3"> shape the
-- product page expects (see feedback_what_youll_learn_card_markup_normalization).
--
-- SG-guarded; C-prefix SKUs and these url_keys are SG-only (partner no-op).
-- Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_pname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_purlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_pmetat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_pmetad  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_pdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_psdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_pcimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @multi := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'multi-agents-series' LIMIT 1);

-- ===== C20 -> Build One Person Company with Multi AI Agents =====

SET @e_C20 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C20' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e_C20, 'Build One Person Company with Multi AI Agents' FROM dual WHERE @e_C20 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C20 AND attribute_id = @a_pname AND store_id <> 0 AND @e_C20 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e_C20, 'build-one-person-company-with-multi-ai-agents' FROM dual WHERE @e_C20 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C20 AND attribute_id = @a_purlkey AND store_id <> 0 AND @e_C20 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e_C20, 'Build One Person Company with Multi AI Agents | Tertiary Courses Singapore' FROM dual WHERE @e_C20 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e_C20, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C20-20260830-065523.png' FROM dual WHERE @e_C20 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e_C20, 'Build and run a one-person company powered by multi AI agents - design an agent org chart, automate marketing, sales, delivery and back office, and scale solo.' FROM dual WHERE @e_C20 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e_C20, '<p>Run a one-person company on a team of AI agents. This hands-on course shows solo founders, freelancers and small operators how to design an agent workforce that handles marketing, sales, delivery, finance and admin - so one person can operate at the scale of a small team without hiring.</p>' FROM dual WHERE @e_C20 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e_C20, '<!-- LSN_DATA: [{"title": "Topic 1 The One Person Company Model", "subsecs": [{"title": "Why solo operators can now scale", "links": []}, {"title": "Mapping your business into agent-sized jobs", "links": []}, {"title": "Designing your agent org chart", "links": []}, {"title": "Tools and cost of running an agent workforce", "links": []}]}, {"title": "Topic 2 Marketing and Sales Agents", "subsecs": [{"title": "Content and campaign agents", "links": []}, {"title": "Lead research and outreach agents", "links": []}, {"title": "Proposal and follow-up automation", "links": []}, {"title": "Keeping a human voice at scale", "links": []}]}, {"title": "Topic 3 Delivery and Operations Agents", "subsecs": [{"title": "Client onboarding and project agents", "links": []}, {"title": "Research, drafting and QA agents", "links": []}, {"title": "Handoffs between agents", "links": []}, {"title": "Quality control and review gates", "links": []}]}, {"title": "Topic 4 Back Office and Scaling", "subsecs": [{"title": "Finance, invoicing and admin agents", "links": []}, {"title": "Dashboards and weekly reporting", "links": []}, {"title": "Failure modes and safe automation", "links": []}, {"title": "A 90-day rollout plan for your solo business", "links": []}]}] -->
<h3 class="course-topic-h3">Topic 1 The One Person Company Model</h3>
<ul>
<li>Why solo operators can now scale</li>
<li>Mapping your business into agent-sized jobs</li>
<li>Designing your agent org chart</li>
<li>Tools and cost of running an agent workforce</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Marketing and Sales Agents</h3>
<ul>
<li>Content and campaign agents</li>
<li>Lead research and outreach agents</li>
<li>Proposal and follow-up automation</li>
<li>Keeping a human voice at scale</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Delivery and Operations Agents</h3>
<ul>
<li>Client onboarding and project agents</li>
<li>Research, drafting and QA agents</li>
<li>Handoffs between agents</li>
<li>Quality control and review gates</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Back Office and Scaling</h3>
<ul>
<li>Finance, invoicing and admin agents</li>
<li>Dashboards and weekly reporting</li>
<li>Failure modes and safe automation</li>
<li>A 90-day rollout plan for your solo business</li>
</ul>' FROM dual WHERE @e_C20 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e_C20 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e_C20 IS NOT NULL AND @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE request_path = 'manage-multi-agents-with-paperclip.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c20-301', 'manage-multi-agents-with-paperclip.html', 'build-one-person-company-with-multi-ai-agents.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e_C20) AND store_id = 1
  AND request_path <> 'build-one-person-company-with-multi-ai-agents.html' AND @e_C20 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e_C20), 'build-one-person-company-with-multi-ai-agents.html', CONCAT('catalog/product/view/id/', @e_C20), 1, @e_C20
FROM dual WHERE @e_C20 IS NOT NULL AND @is_sg > 0;

-- ===== C349 -> Multi AI Agents System for Digital Marketing =====

SET @e_C349 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C349' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e_C349, 'Multi AI Agents System for Digital Marketing' FROM dual WHERE @e_C349 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C349 AND attribute_id = @a_pname AND store_id <> 0 AND @e_C349 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e_C349, 'multi-ai-agents-system-for-digital-marketing' FROM dual WHERE @e_C349 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C349 AND attribute_id = @a_purlkey AND store_id <> 0 AND @e_C349 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e_C349, 'Multi AI Agents System for Digital Marketing | Tertiary Courses Singapore' FROM dual WHERE @e_C349 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e_C349, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C349-20260830-065523.png' FROM dual WHERE @e_C349 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e_C349, 'Build multi AI agent systems for digital marketing - research, content, campaign execution, analytics and optimisation agents working as one pipeline.' FROM dual WHERE @e_C349 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e_C349, '<p>Design a coordinated team of AI agents that runs digital marketing end to end. This practical course covers building multi-agent systems for research, content, campaign execution, analytics and optimisation, so marketing work moves from single prompts to a repeatable agent pipeline.</p>' FROM dual WHERE @e_C349 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e_C349, '<!-- LSN_DATA: [{"title": "Topic 1 Multi Agent Foundations for Marketing", "subsecs": [{"title": "Single agent vs multi agent systems", "links": []}, {"title": "Roles, handoffs and orchestration patterns", "links": []}, {"title": "Choosing frameworks and models", "links": []}, {"title": "Designing a marketing agent pipeline", "links": []}]}, {"title": "Topic 2 Research and Content Agents", "subsecs": [{"title": "Market and competitor research agents", "links": []}, {"title": "Audience and keyword agents", "links": []}, {"title": "Content generation and editing agents", "links": []}, {"title": "Brand voice and quality control", "links": []}]}, {"title": "Topic 3 Campaign Execution Agents", "subsecs": [{"title": "Channel-specific publishing agents", "links": []}, {"title": "Ad copy and creative variant agents", "links": []}, {"title": "Scheduling and coordination", "links": []}, {"title": "Human approval checkpoints", "links": []}]}, {"title": "Topic 4 Analytics and Optimisation", "subsecs": [{"title": "Performance monitoring agents", "links": []}, {"title": "Attribution and reporting", "links": []}, {"title": "Automated experimentation and iteration", "links": []}, {"title": "Deploying and maintaining the system", "links": []}]}] -->
<h3 class="course-topic-h3">Topic 1 Multi Agent Foundations for Marketing</h3>
<ul>
<li>Single agent vs multi agent systems</li>
<li>Roles, handoffs and orchestration patterns</li>
<li>Choosing frameworks and models</li>
<li>Designing a marketing agent pipeline</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Research and Content Agents</h3>
<ul>
<li>Market and competitor research agents</li>
<li>Audience and keyword agents</li>
<li>Content generation and editing agents</li>
<li>Brand voice and quality control</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Campaign Execution Agents</h3>
<ul>
<li>Channel-specific publishing agents</li>
<li>Ad copy and creative variant agents</li>
<li>Scheduling and coordination</li>
<li>Human approval checkpoints</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Analytics and Optimisation</h3>
<ul>
<li>Performance monitoring agents</li>
<li>Attribution and reporting</li>
<li>Automated experimentation and iteration</li>
<li>Deploying and maintaining the system</li>
</ul>' FROM dual WHERE @e_C349 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e_C349 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e_C349 IS NOT NULL AND @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-vibe-coding-for-multi-agent-ai-systems.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c349-301', 'ai-vibe-coding-for-multi-agent-ai-systems.html', 'multi-ai-agents-system-for-digital-marketing.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e_C349) AND store_id = 1
  AND request_path <> 'multi-ai-agents-system-for-digital-marketing.html' AND @e_C349 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e_C349), 'multi-ai-agents-system-for-digital-marketing.html', CONCAT('catalog/product/view/id/', @e_C349), 1, @e_C349
FROM dual WHERE @e_C349 IS NOT NULL AND @is_sg > 0;

-- ===== C1164 -> Multi AI Agents System for Algorithmic Trading =====

SET @e_C1164 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1164' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e_C1164, 'Multi AI Agents System for Algorithmic Trading' FROM dual WHERE @e_C1164 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C1164 AND attribute_id = @a_pname AND store_id <> 0 AND @e_C1164 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e_C1164, 'multi-ai-agents-system-for-algorithmic-trading' FROM dual WHERE @e_C1164 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C1164 AND attribute_id = @a_purlkey AND store_id <> 0 AND @e_C1164 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e_C1164, 'Multi AI Agents System for Algorithmic Trading | Tertiary Courses Singapore' FROM dual WHERE @e_C1164 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e_C1164, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1164-20260830-065524.png' FROM dual WHERE @e_C1164 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM core_url_rewrite
WHERE request_path = 'multi-agents-system-for-algorithmic-trading.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c1164-301', 'multi-agents-system-for-algorithmic-trading.html', 'multi-ai-agents-system-for-algorithmic-trading.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e_C1164) AND store_id = 1
  AND request_path <> 'multi-ai-agents-system-for-algorithmic-trading.html' AND @e_C1164 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e_C1164), 'multi-ai-agents-system-for-algorithmic-trading.html', CONCAT('catalog/product/view/id/', @e_C1164), 1, @e_C1164
FROM dual WHERE @e_C1164 IS NOT NULL AND @is_sg > 0;

-- ===== C: curated non-WSQ order (101..107) =====

UPDATE core_config_data
SET value = CONCAT(value, ',multi-agents-series')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%multi-agents-series%';

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C20' THEN 101
  WHEN 'C349' THEN 102
  WHEN 'C1164' THEN 103
  WHEN 'C765' THEN 104
  WHEN 'C829' THEN 105
  WHEN 'C1034' THEN 106
  WHEN 'C991' THEN 107
END
WHERE cp.category_id = @multi
  AND p.sku IN (
    'C20',
    'C349',
    'C1164',
    'C765',
    'C829',
    'C1034',
    'C991'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C20' THEN 101
  WHEN 'C349' THEN 102
  WHEN 'C1164' THEN 103
  WHEN 'C765' THEN 104
  WHEN 'C829' THEN 105
  WHEN 'C1034' THEN 106
  WHEN 'C991' THEN 107
END
WHERE i.category_id = @multi
  AND p.sku IN (
    'C20',
    'C349',
    'C1164',
    'C765',
    'C829',
    'C1034',
    'C991'
  );

