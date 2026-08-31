-- 1296: Add two more catalog pages under WSQ AI Courses (325) by activating and
-- repurposing two deactivated categories, then set the final sibling order.
--
--   234  Autodesk Navisworks  -> WSQ Multi AI Agents Courses
--        url_key autodesk-navisworks-training -> wsq-multi-ai-agents-courses
--   383  Microsoft Access     -> WSQ AI Applications Courses
--        url_key microsoft-access-training    -> wsq-ai-applications-courses
--
-- Both were chosen because they are inactive at store 0, are LEAF categories
-- (no children to drag along), carry only two stale product rows each, and have
-- no store-scoped is_active/include_in_menu overrides to fight.
--
-- Slugs align to the new titles per the owner's instruction. Both old slugs are
-- live and indexed, so each gets a 301 (options='RP') at store 0 and store 1.
--
-- A repurpose only changes what you explicitly write, so this overwrites ALL of
-- the carried-over state — name, url_key, url_path, description, meta title /
-- description / keywords, parent, path, level, position, layout — and clears
-- the stale products. Anything left unwritten would serve Navisworks / Access
-- copy under the new title.
--
-- FINAL ORDER under WSQ AI Courses (325):
--   1 WSQ Generative AI Courses      (379)
--   2 WSQ Agentic AI Courses         (196)
--   3 WSQ AI Agents Courses          (194)
--   4 WSQ Multi AI Agents Courses    (234)
--   5 WSQ AI Applications Courses    (383)
--   6 WSQ AI Vibe Coding Courses     (425)
--   7 WSQ AI Security Courses        (284)
-- Written explicitly so all seven stay DISTINCT — duplicate positions make the
-- sort non-deterministic and the mega-menu flyout render unreliably.
--
-- umm_dd_type stays '0' (inherit): these are level-4 categories, and Classic
-- must never be set at level <= 3 or the whole column stops expanding.
--
-- Membership is applied by 1297. Business-key lookups only. Idempotent.

SET @uk := (SELECT attribute_id FROM eav_attribute
            WHERE entity_type_id = 3 AND attribute_code = 'url_key' LIMIT 1);
SET @nm := (SELECT attribute_id FROM eav_attribute
            WHERE entity_type_id = 3 AND attribute_code = 'name' LIMIT 1);

SET @c_multi := COALESCE(
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='autodesk-navisworks-training' LIMIT 1),
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='wsq-multi-ai-agents-courses' LIMIT 1));

SET @c_apps := COALESCE(
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='microsoft-access-training' LIMIT 1),
  (SELECT entity_id FROM catalog_category_entity_varchar
   WHERE store_id=0 AND attribute_id=@uk AND value='wsq-ai-applications-courses' LIMIT 1));

SET @parent := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id=0 AND attribute_id=@nm AND value='WSQ AI Courses' LIMIT 1);

-- ------------------------------------------------------- 301 the old slugs
-- Delete the old self-rewrites FIRST. core_url_rewrite is UNIQUE on
-- (request_path, store_id); if the old rows are still present when the 301s
-- are inserted, ON DUPLICATE KEY UPDATE rewrites those rows in place and a
-- later delete by the old id_path removes the 301 with them, leaving the
-- old URL 404ing at store 1.
DELETE FROM core_url_rewrite
WHERE id_path IN (CONCAT('category/', @c_multi), CONCAT('category/', @c_apps))
  AND @c_multi IS NOT NULL AND @c_apps IS NOT NULL;

INSERT INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, CONCAT('category/', @c_multi, '-301'),
       'autodesk-navisworks-training.html', 'wsq-multi-ai-agents-courses.html',
       0, 'RP', 'Autodesk Navisworks -> WSQ Multi AI Agents Courses'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @c_multi IS NOT NULL
ON DUPLICATE KEY UPDATE target_path=VALUES(target_path), options=VALUES(options), is_system=VALUES(is_system);

INSERT INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, CONCAT('category/', @c_apps, '-301'),
       'microsoft-access-training.html', 'wsq-ai-applications-courses.html',
       0, 'RP', 'Microsoft Access -> WSQ AI Applications Courses'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @c_apps IS NOT NULL
ON DUPLICATE KEY UPDATE target_path=VALUES(target_path), options=VALUES(options), is_system=VALUES(is_system);

-- ---------------------------------------------------------------- structure
UPDATE catalog_category_entity c
JOIN catalog_category_entity p ON p.entity_id = @parent
SET c.parent_id = @parent,
    c.path      = CONCAT(p.path, '/', c.entity_id),
    c.level     = p.level + 1
WHERE c.entity_id IN (@c_multi, @c_apps)
  AND @c_multi IS NOT NULL AND @c_apps IS NOT NULL AND @parent IS NOT NULL;

-- ------------------------------------------------------------ varchar attrs
DROP TEMPORARY TABLE IF EXISTS tmp_v;
CREATE TEMPORARY TABLE tmp_v (cat INT, code VARCHAR(64), val TEXT, PRIMARY KEY (cat, code));
INSERT INTO tmp_v (cat, code, val) VALUES
 (@c_multi,'name',        'WSQ Multi AI Agents Courses'),
 (@c_multi,'url_key',     'wsq-multi-ai-agents-courses'),
 (@c_multi,'url_path',    'wsq-multi-ai-agents-courses.html'),
 (@c_multi,'meta_title',  'WSQ Multi AI Agents Courses - Build Multi-Agent AI Systems | Tertiary Courses Singapore'),
 (@c_multi,'display_mode','PRODUCTS'),
 (@c_multi,'page_layout', 'two_columns_left'),
 (@c_multi,'umm_dd_type', '0'),
 (@c_apps, 'name',        'WSQ AI Applications Courses'),
 (@c_apps, 'url_key',     'wsq-ai-applications-courses'),
 (@c_apps, 'url_path',    'wsq-ai-applications-courses.html'),
 (@c_apps, 'meta_title',  'WSQ AI Applications Courses - AI for Industry and Business | Tertiary Courses Singapore'),
 (@c_apps, 'display_mode','PRODUCTS'),
 (@c_apps, 'page_layout', 'two_columns_left'),
 (@c_apps, 'umm_dd_type', '0');

DELETE v FROM catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3
JOIN tmp_v t ON t.cat=v.entity_id AND t.code=a.attribute_code
WHERE v.store_id <> 0;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, t.cat, t.val
FROM tmp_v t JOIN eav_attribute a ON a.entity_type_id=3 AND a.attribute_code=t.code
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- --------------------------------------------------------------- text attrs
DROP TEMPORARY TABLE IF EXISTS tmp_t;
CREATE TEMPORARY TABLE tmp_t (cat INT, code VARCHAR(64), val TEXT, PRIMARY KEY (cat, code));

INSERT INTO tmp_t (cat, code, val) VALUES
(@c_multi,'description', CONCAT(
'<p>A single AI agent can only carry so much. Multi-agent systems break a large goal into roles — a researcher, a writer, a reviewer, a coder, a tester — and let specialised agents work in parallel, hand off results and check each other''s output. The pattern mirrors how human teams operate, and it consistently outperforms one general-purpose agent on complex, multi-step work.</p>',
'<p>Our WSQ Multi AI Agents Courses teach how to design, build and operate these systems with the frameworks the industry has standardised on — AutoGen, CrewAI, Google Agent Development Kit and related orchestration tooling. Participants learn to decompose a goal into agent roles, define how agents communicate and hand off, manage shared memory and context, add human-in-the-loop checkpoints, and deploy the result as a running application rather than a notebook demo.</p>',
'<p>The catalogue spans practical build courses and applied workflows: content-creation pipelines where research, drafting and editing agents collaborate, autonomous agent teams that operate with minimal supervision, agent management and orchestration, and vibe-coded multi-agent systems for developers who want to assemble them quickly with AI assistance. Courses also cover the operational realities that decide whether a multi-agent deployment survives contact with production — controlling cost and token spend, preventing runaway loops, tracing failures across agents, and knowing when a simpler single-agent design is the better answer.</p>',
'<h3>What you will learn</h3><ul>',
'<li>Designing multi-agent architectures - roles, responsibilities, handoffs and communication</li>',
'<li>Building agent teams with AutoGen, CrewAI, Google ADK and related frameworks</li>',
'<li>Orchestrating collaborative workflows such as research, drafting, review and approval</li>',
'<li>Managing shared context, memory and state across cooperating agents</li>',
'<li>Adding human-in-the-loop checkpoints, guardrails and approval gates</li>',
'<li>Deploying, monitoring, tracing and cost-controlling multi-agent systems in production</li></ul>',
'<h3>Who should attend</h3>',
'<p>Developers and AI engineers building agentic applications, data and automation specialists designing intelligent workflows, technical leads evaluating agent frameworks, and product and operations managers who need to understand what multi-agent systems can realistically deliver.</p>',
'<h3>Funding</h3>',
'<p>These are WSQ, CASL and IBF funded courses. Eligible Singaporeans and PRs can enjoy SkillsFuture funding subsidies, and SkillsFuture Credit may be used to offset the nett course fee. Company-sponsored participants may also be eligible for SkillsFuture Enterprise Credit (SFEC) and absentee payroll. Please refer to each course page for the funding schemes that apply.</p>')),

(@c_multi,'meta_description',
'WSQ Multi AI Agents Courses in Singapore. Build and orchestrate multi-agent AI systems with AutoGen, CrewAI and Google ADK - agent roles, handoffs, workflows and production deployment. SkillsFuture funded.'),

(@c_multi,'meta_keywords',
'WSQ multi AI agents course Singapore, multi agent systems training, AutoGen course, CrewAI course, Google Agent Development Kit, agent orchestration, multi agent workflow, agentic AI applications, autonomous agent teams, human in the loop AI, SkillsFuture multi agent, WSQ funded AI training, CASL AI agents, build AI agent team'),

(@c_apps,'description', CONCAT(
'<p>AI creates value when it is applied to a real business problem — screening candidates, detecting fraud, forecasting demand, reading medical or scientific data, personalising a storefront. Our WSQ AI Applications Courses are organised around exactly that: the industries and business functions where AI is already in production, and what it takes to deploy it there responsibly.</p>',
'<p>The catalogue spans financial services (machine learning for trading, financial data mining and modeling, deep learning and analytics for financial services, AI-assisted Python for finance, generative AI for finance and fintech), healthcare and life sciences (data analytics and AI for healthcare, AI for life science and bioinformatics), business functions such as HR, recruitment, product development and eCommerce, and broad business innovation and transformation with AI.</p>',
'<p>Alongside the applied tracks sit the technical foundations these applications rest on: machine learning and data mining fundamentals, computer vision, text mining and analytics, pattern recognition, reinforcement learning, PyTorch, and model development and fine-tuning. Recognised cloud AI certifications complete the picture — Microsoft Azure AI, AWS AI and machine learning, and Google Professional Machine Learning Engineer — for professionals who want a credential alongside the capability.</p>',
'<h3>What you will learn</h3><ul>',
'<li>Applying AI and machine learning to finance, healthcare, life sciences, HR, retail and eCommerce</li>',
'<li>Core techniques - machine learning, data mining, computer vision, NLP and text analytics, reinforcement learning</li>',
'<li>Building, fine-tuning and evaluating models with PyTorch and modern AI toolchains</li>',
'<li>Identifying high-value AI use cases and building the business case for adoption</li>',
'<li>Deploying AI responsibly within regulatory and governance expectations</li>',
'<li>Preparing for Microsoft Azure AI, AWS AI/ML and Google Machine Learning Engineer certifications</li></ul>',
'<h3>Who should attend</h3>',
'<p>Business and data analysts, finance and banking professionals, healthcare and life-science practitioners, HR and marketing professionals, IT and engineering staff moving into AI, and managers responsible for AI adoption in their function. Courses range from business-level to hands-on technical.</p>',
'<h3>Funding</h3>',
'<p>These are WSQ, CASL and IBF funded courses. Eligible Singaporeans and PRs can enjoy SkillsFuture funding subsidies, and SkillsFuture Credit may be used to offset the nett course fee. IBF-accredited courses carry IBF funding for eligible finance-sector participants. Company-sponsored participants may also be eligible for SkillsFuture Enterprise Credit (SFEC) and absentee payroll. Please refer to each course page for the schemes that apply.</p>')),

(@c_apps,'meta_description',
'WSQ AI Applications Courses in Singapore. Apply AI and machine learning to finance, healthcare, HR, retail and eCommerce, plus Azure, AWS and Google AI certifications. SkillsFuture and IBF funded.'),

(@c_apps,'meta_keywords',
'WSQ AI applications course Singapore, AI for finance, AI for healthcare, AI for HR, AI for eCommerce, machine learning course Singapore, IBF AI course, financial data mining, deep learning financial services, computer vision course, reinforcement learning, PyTorch training, Azure AI certification, AWS machine learning certification, Google machine learning engineer, SkillsFuture AI training, CASL AI course');

DELETE x FROM catalog_category_entity_text x
JOIN eav_attribute a ON a.attribute_id=x.attribute_id AND a.entity_type_id=3
JOIN tmp_t t ON t.cat=x.entity_id AND t.code=a.attribute_code
WHERE x.store_id <> 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, t.cat, t.val
FROM tmp_t t JOIN eav_attribute a ON a.entity_type_id=3 AND a.attribute_code=t.code
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------- int attrs
DROP TEMPORARY TABLE IF EXISTS tmp_i;
CREATE TEMPORARY TABLE tmp_i (cat INT, code VARCHAR(64), val INT, PRIMARY KEY (cat, code));
INSERT INTO tmp_i (cat, code, val)
SELECT c.cat, k.code, k.val FROM
 (SELECT @c_multi AS cat UNION ALL SELECT @c_apps) c,
 (SELECT 'is_active' AS code, 1 AS val UNION ALL
  SELECT 'include_in_menu', 1 UNION ALL
  SELECT 'is_anchor', 1 UNION ALL
  SELECT 'custom_use_parent_settings', 0 UNION ALL
  SELECT 'custom_apply_to_products', 0) k;

-- Store-scoped is_active/include_in_menu=0 rows would shadow store 0 and keep
-- the pages dead and out of the menu.
DELETE i FROM catalog_category_entity_int i
JOIN eav_attribute a ON a.attribute_id=i.attribute_id AND a.entity_type_id=3
JOIN tmp_i t ON t.cat=i.entity_id AND t.code=a.attribute_code
WHERE i.store_id <> 0;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, t.cat, t.val
FROM tmp_i t JOIN eav_attribute a ON a.entity_type_id=3 AND a.attribute_code=t.code
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear the stale Navisworks / Access products.
DELETE FROM catalog_category_product
WHERE category_id IN (@c_multi, @c_apps) AND @c_multi IS NOT NULL AND @c_apps IS NOT NULL;
DELETE FROM catalog_category_product_index
WHERE category_id IN (@c_multi, @c_apps) AND @c_multi IS NOT NULL AND @c_apps IS NOT NULL;

-- ------------------------------------------------------------ final ordering
SET @c_gen  := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id=0 AND attribute_id=@uk AND value='wsq-generative-ai-courses' LIMIT 1);
SET @c_agt  := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id=0 AND attribute_id=@uk AND value='wsq-agentic-ai-courses' LIMIT 1);
SET @c_agts := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id=0 AND attribute_id=@uk AND value='wsq-ai-agents-courses' LIMIT 1);
SET @c_vibe := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id=0 AND attribute_id=@uk AND value='wsq-ai-vibe-coding-courses' LIMIT 1);
SET @c_sec  := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id=0 AND attribute_id=@uk AND value='wsq-ai-security-courses' LIMIT 1);

UPDATE catalog_category_entity
SET position = CASE entity_id
      WHEN @c_gen   THEN 1
      WHEN @c_agt   THEN 2
      WHEN @c_agts  THEN 3
      WHEN @c_multi THEN 4
      WHEN @c_apps  THEN 5
      WHEN @c_vibe  THEN 6
      WHEN @c_sec   THEN 7
      ELSE position END
WHERE entity_id IN (@c_gen, @c_agt, @c_agts, @c_multi, @c_apps, @c_vibe, @c_sec);
