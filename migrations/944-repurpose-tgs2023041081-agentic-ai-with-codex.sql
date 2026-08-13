-- 944: Repurpose TGS-2023041081
--   FROM "WSQ - Develop Generative AI Apps in <ZWSP>Azure AI Foundry (AI-3016)"
--   TO   "WSQ - Agentic AI Applications with Codex"
-- SKU is UNCHANGED (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
--
-- Surfaces touched (per the TGS- rename checklist):
--   1  name                      -> WSQ - Agentic AI Applications with Codex (drops the
--                                   stray U+200B zero-width space the old title carried)
--   2  meta_title                -> plain title, no "WSQ" prefix, no brand suffix
--                                   (MMD_Seotitle composes both at render time)
--   3  url_key + url_path DELETE  -> wsq-agentic-ai-applications-with-codex + explicit 301
--   4  short_description          -> new About This Course prose (also drops a stray
--                                   "Autodesk Exam Voucher" section that never belonged)
--   5  *_label + media gallery    -> plain title (alt text on the cover)
--   6  learning_outcomes block    -> new LO1-LO4
--   6b description (+LSN_DATA)    -> new Topic 1-4
--   7  trainerprofile             -> para-2 teaching claims only; para-1 credentials kept
--   8  meta_description / meta_keyword / whoshouldattend / prerequisite
--   9  categories                 -> drop Azure/Microsoft/Cloud (course no longer teaches
--                                   Azure); add the Agentic/Codex placements its sibling
--                                   TGS-2025052468 (Claude Code) holds. Mirrored into
--                                   catalog_category_product_index.
--
-- Deliberately unchanged: sku, price, duration, sessions, tags/badges (WSQ, SFC, PSEA,
--   UTAP, SFEC, MCES, Absentee Payroll all still apply), the brochure / certification /
--   skills_framework / funding_and_grant cms_blocks (all keyed on the unchanged SKU),
--   image/small_image/thumbnail filesystem paths (paths, not display text), and
--   course_image_url (cover PNG is re-rendered from the admin, not by SQL).
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every statement no-ops.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023041081' LIMIT 1);

SET @a_name     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_desc     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_who      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_trainer  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_ilabel   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slabel   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlabel   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------------ 1. name
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Agentic AI Applications with Codex'
 WHERE entity_id = @e AND attribute_id = @a_name;

-- ------------------------------------------------------- 2. meta_title / SEO
-- Plain title only: MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs and
-- appends "| Tertiary Courses Singapore" at render time.
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI Applications with Codex'
 WHERE entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to design, build, test and optimise agentic AI applications with Codex - skills, MCP tools, RAG and multi-agent workflows. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
   SET value = 'Codex course Singapore, agentic AI applications, WSQ AI course Singapore, AI coding agent training, MCP tools course, Codex skills, RAG application development, multi-agent AI course, AI agent development course, WSQ AI certification'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND store_id = 0;

-- ------------------------------------------------------------- 3. url_key
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-agentic-ai-applications-with-codex'
 WHERE entity_id = @e AND attribute_id = @a_urlkey;

-- Drop url_path at EVERY scope so the URL Rewrites indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlpath;

-- Clear any non-system squatter sitting on the new path first, otherwise the
-- INSERT IGNORE below silently no-ops against the stale row (see migration 647).
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-agentic-ai-applications-with-codex.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old bare slug. The indexer auto-301s the ~20 category
-- paths; this covers the flat URL that is linked from off-site.
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1,
       CONCAT('rp_tgs2023041081_azurefoundry_', 1),
       'wsq-develop-generative-ai-apps-in-azure-ai-foundry-ai-3016.html',
       'wsq-agentic-ai-applications-with-codex.html',
       0, 'RP', '944 rename: Azure AI Foundry -> Agentic AI with Codex'
  FROM dual WHERE @e IS NOT NULL;

-- The course was renamed once before; keep that older alias pointing at the
-- live page instead of leaving it aimed at a now-dead slug (301 chain).
UPDATE core_url_rewrite
   SET target_path = 'wsq-agentic-ai-applications-with-codex.html'
 WHERE is_system = 0
   AND target_path = 'wsq-develop-generative-ai-apps-in-azure-ai-foundry-ai-3016.html'
   AND @e IS NOT NULL;

-- ------------------------------------------------------- 4. image alt labels
UPDATE catalog_product_entity_varchar
   SET value = 'Agentic AI Applications with Codex'
 WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
  JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
   SET v.label = 'Agentic AI Applications with Codex'
 WHERE g.entity_id = @e;

-- --------------------------------------------------- 5. Learning Outcomes
-- Guarded INSERT first: courses predating the 885-891 block extraction may have
-- no block at all, in which case a bare UPDATE silently no-ops.
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2023041081 - Learning Outcomes',
       'course_TGS-2023041081_learning_outcomes',
       '', NOW(), NOW(), 1
  FROM dual
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM cms_block) b
                    WHERE b.identifier = 'course_TGS-2023041081_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
 WHERE b.identifier = 'course_TGS-2023041081_learning_outcomes' AND @e IS NOT NULL;

UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1 - Analyze range of agentic AI applications and identify their strengths, limitations, and industry applicability.</li>
<li>LO2 - Establish the correlation between agentic AI algorithm design and efficiency, and evaluate process improvement.</li>
<li>LO3 - Assess agentic AI application effectiveness evaluation methods.</li>
<li>LO4 - Evaluate agentic AI applications focusing on performance effectiveness and comparative analysis.</li>
</ul>',
       update_time = NOW()
 WHERE identifier = 'course_TGS-2023041081_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------- 6. Course Outline (description + JSON)
-- The LSN_DATA JSON comment drives the admin editor; keep it byte-aligned with
-- the visible markup below it.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: Agentic AI Application Planning and Development with Codex","subsecs":[]},{"title":"Topic 2: Building Reusable AI Workflows with Codex Skills and MCP Tools","subsecs":[]},{"title":"Topic 3: Developing RAG and Multi-Agent Applications with Codex","subsecs":[]},{"title":"Topic 4: Testing, Evaluating and Optimising Agentic AI Applications","subsecs":[]}] -->
<p><strong>Topic 1: Agentic AI Application Planning and Development with Codex</strong></p>
<p><strong>Topic 2: Building Reusable AI Workflows with Codex Skills and MCP Tools</strong></p>
<p><strong>Topic 3: Developing RAG and Multi-Agent Applications with Codex</strong></p>
<p><strong>Topic 4: Testing, Evaluating and Optimising Agentic AI Applications</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- ------------------------------------------------ 7. About This Course (sdesc)
-- Post-885 block model: this product's short_description is prose only (the
-- section HTML lives in cms_blocks), so a full replace is safe. The outgoing
-- value also carried a stray "Exam Voucher / Autodesk" section that belonged to
-- a different course; it is dropped here.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips learners with practical skills to design, build, test, and optimise agentic AI applications using Codex. Participants will use Codex as an AI coding agent to translate application requirements into working software, understand existing codebases, generate and refactor code, diagnose issues, and validate solutions through testing and review.</p>
<p>Learners will explore the core components of agentic applications, including structured workflows, tool use, memory, context management, retrieval-augmented generation (RAG), action loops, human approvals, and multi-agent coordination. They will connect applications to external systems and data sources using Model Context Protocol (MCP) tools and develop reusable Skills for consistent, task-specific workflows.</p>
<p>The course covers the end-to-end development process, from defining use cases and planning system architecture to implementing interfaces, integrating APIs, managing data, and deploying functional applications. Participants will also use Codex to create tests, evaluate outputs, troubleshoot failures, improve reliability, and document their solutions.</p>
<p>Emphasis is placed on secure coding, permission control, data privacy, responsible AI practices, and human oversight. By the end of the course, learners will be able to use Codex to develop production-oriented agentic AI applications that can retrieve information, use tools, complete multi-step tasks, and support real-world business processes.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0;

-- ------------------------------------------------------- 8. whoshouldattend
-- The old list named the retired technology ("Azure AI Engineer"); repoint the
-- Azure-specific roles at their platform-neutral agentic-AI equivalents.
UPDATE catalog_product_entity_text
   SET value = '<ul>
<li>AI Developer</li>
<li>Machine Learning Engineer</li>
<li>AI Solutions Architect</li>
<li>Data Scientist</li>
<li>AI Agent Engineer</li>
<li>Software Developer</li>
<li>AI Product Manager</li>
<li>Data Engineer</li>
<li>Prompt Engineer</li>
<li>AI Automation Consultant</li>
<li>Application Developer</li>
<li>R&amp;D Engineer (AI)</li>
<li>Technical Consultant (AI)</li>
<li>Business Intelligence Analyst</li>
<li>Innovation Manager</li>
<li>Systems Analyst</li>
<li>Tech Project Manager</li>
<li>Automation Engineer</li>
<li>AI Research Assistant</li>
<li>Solution Developer</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_who AND store_id = 0;

-- ------------------------------------------------------------ 9. prerequisite
-- This attribute ALSO holds the whole funding apparatus (PWM, Funding
-- Eligibility table, SkillsFuture / PSEA / SFEC / UTAP deep links, Appeal
-- Process) => never rewrite it wholesale. Replace ONLY the <li>/<p> holding the
-- Azure account sign-up link. Single-line REPLACE (the blob is CRLF WYSIWYG
-- content, so a multi-line pattern would silently no-op).
UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        '<p>You need to sign up a <span style="text-decoration: underline;"><a href="https://azure.microsoft.com/en-us" target="_blank">Azure account (Credit Card is required).</a></span></p>',
        '<p>You need an <span style="text-decoration: underline;"><a href="https://openai.com/codex/" target="_blank">OpenAI Codex account</a></span> (a paid ChatGPT plan is required).</p>')
 WHERE entity_id = @e AND attribute_id = @a_prereq AND store_id = 0;

-- --------------------------------------------------------- 10. trainerprofile
-- Each bio is two paragraphs: para 1 = career CREDENTIALS (real, keep verbatim),
-- para 2 = a course-teaching claim scoped to the retired topic (retarget).
-- Targeted REPLACE() per bio so the &ndash; / &rsquo; entities survive.
UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        'ensuring learners gain confidence in developing Generative AI apps on Azure AI Foundry.',
        'ensuring learners gain confidence in developing agentic AI applications with Codex.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0;

UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        'In the Azure AI Foundry training, Sanjiv leverages his data analytics and business applications experience to guide learners in applying Generative AI tools for real-world use cases.',
        'In the Agentic AI Applications with Codex training, Sanjiv leverages his data analytics and business applications experience to guide learners in applying AI coding agents to real-world use cases.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0;

UPDATE catalog_product_entity_text
   SET value = REPLACE(
        value,
        'For the WSQ &ndash; Develop Generative AI Apps in Azure AI Foundry program, Alfred draws on his strong background in cloud systems and secure digital infrastructure. He equips learners with the skills to design, deploy, and manage AI-driven solutions on Azure, while emphasizing governance and security best practices. His structured, hands-on teaching style ensures participants are prepared to apply Generative AI models in production-ready business applications.',
        'For the WSQ &ndash; Agentic AI Applications with Codex program, Alfred draws on his strong background in cloud systems and secure digital infrastructure. He equips learners with the skills to design, deploy, and manage agentic AI applications, while emphasizing permission control, governance and security best practices. His structured, hands-on teaching style ensures participants are prepared to apply AI coding agents in production-ready business applications.')
 WHERE entity_id = @e AND attribute_id = @a_trainer AND store_id = 0;

-- --------------------------------------------------------- 11. categories
-- The course no longer teaches Azure / Microsoft cloud, so drop the placements
-- that now misdescribe it: 11 Microsoft, 87 Cloud Computing, 185 Azure,
-- 426 WSQ Cloud Computing & Networking. Also drop 72 WSQ Media & Marketing
-- (never applicable to a developer course).
-- KEEP the broad parents: 3 All Courses, 15 WSQ and IBF, 55 Infocomm Technology,
-- 200 GenAI Content Creation, 252 AI Courses, 292 WSQ Funded, 301 WSQ IT &
-- Security, 379 WSQ Generative AI, 433 Generative AI Series.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (11, 72, 87, 185, 426) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (11, 72, 87, 185, 426) AND @e IS NOT NULL;

-- Add the agentic placements its sibling TGS-2025052468 (WSQ - Agentic AI
-- Applications with Claude Code) already holds, plus the Codex AI Series that
-- mirrors the Claude AI Series. Appended at MAX(position)+1 so the
-- category-ordering sweep can renumber later.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.cid, @e,
       COALESCE((SELECT MAX(x.position) FROM (SELECT * FROM catalog_category_product) x
                  WHERE x.category_id = c.cid), 0) + 1
  FROM (SELECT 189 AS cid UNION ALL SELECT 196 UNION ALL SELECT 283 UNION ALL SELECT 325) c
 WHERE @e IS NOT NULL;

-- Mirror into the index or the storefront listings never change.
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT ccp.category_id, ccp.product_id, ccp.position, 1, s.store_id, 4
  FROM catalog_category_product ccp
  CROSS JOIN (SELECT store_id FROM core_store WHERE store_id > 0) s
 WHERE ccp.product_id = @e
   AND ccp.category_id IN (189, 196, 283, 325)
   AND @e IS NOT NULL;
