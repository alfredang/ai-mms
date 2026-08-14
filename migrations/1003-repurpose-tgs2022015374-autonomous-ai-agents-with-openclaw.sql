-- 1002-repurpose-tgs2022015374-autonomous-ai-agents-with-openclaw.sql
-- Repurpose TGS-2022015374:
--   'WSQ - Business Transformation with OpenClaw and NFT'
--     -> 'WSQ - Autonomous AI Agents with OpenClaw'
-- SKU is UNCHANGED (SkillsFuture/SFEC/SFC/PSEA deep links stay valid).
-- SG-only: TGS- SKUs do not exist on MY/GH, so @e is NULL there and every
-- statement below is a guarded no-op on partner servers.
-- Idempotent: re-running converges (upserts + guarded REPLACE()s).

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2022015374');

-- attribute ids (entity_type_id 4 = catalog_product)
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'name' AND entity_type_id = 4);
SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_key' AND entity_type_id = 4);
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_path' AND entity_type_id = 4);
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_title' AND entity_type_id = 4);
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_description' AND entity_type_id = 4);
SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_keyword' AND entity_type_id = 4);
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'short_description' AND entity_type_id = 4);
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'description' AND entity_type_id = 4);
SET @a_wsa := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'whoshouldattend' AND entity_type_id = 4);
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'trainerprofile' AND entity_type_id = 4);
SET @a_il := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'image_label' AND entity_type_id = 4);
SET @a_sil := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'small_image_label' AND entity_type_id = 4);
SET @a_til := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'thumbnail_label' AND entity_type_id = 4);

-- ---------------------------------------------------------------- 1. name + labels
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'WSQ - Autonomous AI Agents with OpenClaw' FROM dual WHERE @e IS NOT NULL AND @a_name IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_name AND store_id <> 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Autonomous AI Agents with OpenClaw' FROM dual WHERE @e IS NOT NULL AND @a_il IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_il AND store_id <> 0;
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Autonomous AI Agents with OpenClaw' FROM dual WHERE @e IS NOT NULL AND @a_sil IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_sil AND store_id <> 0;
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Autonomous AI Agents with OpenClaw' FROM dual WHERE @e IS NOT NULL AND @a_til IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_til AND store_id <> 0;

-- media-gallery per-image label (renders as the zoom gallery img alt/title)
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'Autonomous AI Agents with OpenClaw'
  WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------- 2. meta fields
-- meta_title stays PLAIN: MMD_Seotitle prepends 'WSQ funded' and appends the brand
-- postfix at render time. The old value baked in both (double-brand bug).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Autonomous AI Agents with OpenClaw' FROM dual WHERE @e IS NOT NULL AND @a_mt IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_mt AND store_id <> 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Learn to build, deploy and manage autonomous AI agents with OpenClaw. Master agent workflows, tools, memory, multi-agent coordination and secure deployment. Enjoy up to 70% WSQ funding subsidy.' FROM dual WHERE @e IS NOT NULL AND @a_md IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_md AND store_id <> 0;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'WSQ course Singapore, OpenClaw, autonomous AI agents, AI agent workflows, agentic AI, multi-agent coordination, retrieval augmented generation, agent memory, AI automation, prompt injection defence, SkillsFuture, WSQ funding, digital transformation' FROM dual WHERE @e IS NOT NULL AND @a_mk IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_text WHERE entity_id = @e AND attribute_id = @a_mk AND store_id <> 0;

-- ---------------------------------------------------------------- 3. url_key + 301
-- Clear url_path at EVERY scope so the URL Rewrites indexer regenerates it.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'wsq-autonomous-ai-agents-with-openclaw' FROM dual WHERE @e IS NOT NULL AND @a_url IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_url AND store_id <> 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_upath;

-- Drop any non-system squatter holding the NEW path (INSERT IGNORE would no-op on it).
DELETE FROM core_url_rewrite WHERE request_path = 'wsq-autonomous-ai-agents-with-openclaw.html' AND is_system = 0;

-- Explicit 301 for the old bare slug (the indexer auto-301s the ~20 category paths).
INSERT INTO core_url_rewrite (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, NULL, 'TGS-2022015374-rp-autonomous', 'wsq-business-transformation-with-openclaw-and-nft.html', 'wsq-autonomous-ai-agents-with-openclaw.html', 0, 'RP'
  FROM core_store s
  WHERE s.store_id > 0 AND @e IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) r
                    WHERE r.store_id = s.store_id AND r.request_path = 'wsq-business-transformation-with-openclaw-and-nft.html');

-- ---------------------------------------------------------------- 4. short_description
-- This course's standard sections (Brochure / Skills Framework / Certification /
-- WSQ Funding) live in cms_block rows, so short_description is prose only and a
-- full replace is correct here (verified: no '<h2>Course Brochure</h2>' tail).
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sdesc, 0, @e, '<p>Autonomous AI Agents with OpenClaw equips learners with the knowledge and practical skills to build, deploy, and manage AI agents that can perform complex tasks with minimal human intervention. Participants will explore how OpenClaw enables AI agents to understand objectives, plan actions, retrieve information, use digital tools, maintain contextual memory, and collaborate with people and other agents.</p>
<p>Through hands-on activities, learners will set up and configure OpenClaw, create specialized agent roles, develop reusable skills, connect tools and APIs, and automate multi-step workflows. They will apply OpenClaw to practical business functions such as research, customer service, sales, marketing, administration, content creation, reporting, and knowledge management. The course also introduces Retrieval-Augmented Generation, persistent memory, context engineering, sub-agents, multi-agent coordination, and human-in-the-loop approvals.</p>
<p>Participants will learn to monitor agent performance, validate outputs, troubleshoot failures, manage token usage, and optimize workflows for reliability and cost efficiency. Emphasis is placed on secure and responsible deployment through least-privilege access, sandboxing, data protection, audit trails, security guardrails, and defence against prompt injection.</p>
<p>By the end of the course, learners will be able to use OpenClaw to develop secure, reliable, and goal-driven autonomous AI agents that improve operational efficiency, support digital transformation, and create new opportunities for business innovation.</p>' FROM dual WHERE @e IS NOT NULL AND @a_sdesc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_text WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id <> 0;

-- ---------------------------------------------------------------- 5. course outline
-- Keep the LSN_DATA JSON comment and the <p><strong>Topic N HTML in sync.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<!-- LSN_DATA: [{"title":"Topic 1: Exploring OpenClaw and the Autonomous AI Agent Landscape","subsecs":[]},{"title":"Topic 2: Evaluating OpenClaw Applications and Business Opportunities","subsecs":[]},{"title":"Topic 3: Designing OpenClaw Agent Workflows and Managing Implementation Risks","subsecs":[]}] -->
<p><strong>Topic 1: Exploring OpenClaw and the Autonomous AI Agent Landscape</strong></p>
<p><strong>Topic 2: Evaluating OpenClaw Applications and Business Opportunities</strong></p>
<p><strong>Topic 3: Designing OpenClaw Agent Workflows and Managing Implementation Risks</strong></p>
<p><em>Final Assessment</em></p>
<p><em>Written Assessment (SAQ)</em></p>' FROM dual WHERE @e IS NOT NULL AND @a_desc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_text WHERE entity_id = @e AND attribute_id = @a_desc AND store_id <> 0;

-- ---------------------------------------------------------------- 6. whoshouldattend
-- The old list named 15 NFT / digital-art roles.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_wsa, 0, @e, '<ul>
<li>AI Automation Specialist</li>
<li>Business Process Analyst</li>
<li>Digital Transformation Consultant</li>
<li>Operations Manager</li>
<li>Product Manager (AI products)</li>
<li>Customer Experience Manager</li>
<li>Marketing Operations Specialist</li>
<li>Sales Operations Analyst</li>
<li>Knowledge Management Specialist</li>
<li>IT Solutions Architect</li>
<li>Software Developer (AI integration)</li>
<li>Data Analyst</li>
<li>Innovation Manager</li>
<li>Technology Risk and Governance Officer</li>
<li>Entrepreneur exploring AI-driven business models.</li>
</ul>' FROM dual WHERE @e IS NOT NULL AND @a_wsa IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_text WHERE entity_id = @e AND attribute_id = @a_wsa AND store_id <> 0;

-- ---------------------------------------------------------------- 7. learning outcomes block
-- Guarded INSERT first: the block may be absent on a rebuilt DB, where a bare
-- UPDATE would silently no-op and the What You'll Learn card would render empty.
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2022015374 – Learning Outcomes', 'course_TGS-2022015374_learning_outcomes', '<p>By the end of the course, learners will be able to&nbsp;</p>
<ul></ul>
<ul>
<li>LO1: Explore and conduct market research on emerging AI technology.</li>
<li>LO2:&nbsp;Assess the potential of emerging AI technology.</li>
<li>LO3:&nbsp;Identify a typical AI process and put forth recommendations to reduce risks.</li>
</ul>', NOW(), NOW(), 1 FROM dual
  WHERE NOT EXISTS (SELECT 1 FROM (SELECT * FROM cms_block) b WHERE b.identifier = 'course_TGS-2022015374_learning_outcomes');
INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b WHERE b.identifier = 'course_TGS-2022015374_learning_outcomes';
UPDATE cms_block SET content = '<p>By the end of the course, learners will be able to&nbsp;</p>
<ul></ul>
<ul>
<li>LO1: Explore and conduct market research on emerging AI technology.</li>
<li>LO2:&nbsp;Assess the potential of emerging AI technology.</li>
<li>LO3:&nbsp;Identify a typical AI process and put forth recommendations to reduce risks.</li>
</ul>', update_time = NOW() WHERE identifier = 'course_TGS-2022015374_learning_outcomes';

-- ---------------------------------------------------------------- 8. trainer bios
-- Each bio is 2 paragraphs: para 1 = career CREDENTIALS (real blockchain/Web3
-- history - left untouched, rewriting it would falsify the bio), para 2 = the
-- course-teaching claim, retargeted here. Note: Terence Ee / Alfred Yap / Jyoti
-- Chopra have central courses_trainers rows that win over this blob at render
-- time, so their edits are dormant-but-correct fallbacks; Shahul's and
-- Shanique's blob names differ from the central titles, so theirs do render.
UPDATE catalog_product_entity_text SET value = REPLACE(value, '<p>In his NFT training, Terence emphasizes the business applications and strategic opportunities of blockchain technologies. He guides learners through NFT use cases for digital art, intellectual property, and brand engagement, while also addressing governance, compliance, and enterprise integration. With his executive-level perspective, he ensures participants understand both the technical foundations and the business models driving NFT adoption.</p>', '<p>In his autonomous AI agent training, Terence emphasizes the business applications and strategic opportunities of agentic AI. He guides learners through OpenClaw agent use cases for research, operations, and customer engagement, while also addressing governance, compliance, and enterprise integration. With his executive-level perspective, he ensures participants understand both the technical foundations and the business models driving autonomous AI agent adoption.</p>')
  WHERE entity_id = @e AND attribute_id = @a_tp AND @e IS NOT NULL;
UPDATE catalog_product_entity_text SET value = REPLACE(value, '<p>In his NFT training, Alfred focuses on bridging technology with business opportunities. He introduces learners to NFT creation, blockchain wallets, and smart contract functionality, ensuring they understand both the technical process and its commercial implications. By integrating his expertise in ERP and cloud systems, Alfred helps participants explore how NFTs can support new business models and digital transformation strategies.</p>', '<p>In his autonomous AI agent training, Alfred focuses on bridging technology with business opportunities. He introduces learners to OpenClaw agent configuration, tool and API integration, and multi-step workflow automation, ensuring they understand both the technical process and its commercial implications. By integrating his expertise in ERP and cloud systems, Alfred helps participants explore how autonomous AI agents can support new business models and digital transformation strategies.</p>')
  WHERE entity_id = @e AND attribute_id = @a_tp AND @e IS NOT NULL;
UPDATE catalog_product_entity_text SET value = REPLACE(value, '<p>In “AI Generated NFT To Drive Business Growth,” Jyoti guides participants through the complete lifecycle of creating, tokenizing, and marketing digital art and assets using AI tools. Her sessions emphasize the intersection of creativity, technology, and strategy—covering AI image generation, NFT minting, and marketplace integration. Through practical demonstrations and real-world examples, she empowers learners to harness AI-generated content as a new avenue for digital branding and revenue growth.</p>', '<p>In “Autonomous AI Agents with OpenClaw,” Jyoti guides participants through the complete lifecycle of designing, building, and deploying AI agents for business tasks. Her sessions emphasize the intersection of creativity, technology, and strategy—covering agent roles, reusable skills, and content and knowledge workflows. Through practical demonstrations and real-world examples, she empowers learners to harness autonomous AI agents as a new avenue for productivity and business growth.</p>')
  WHERE entity_id = @e AND attribute_id = @a_tp AND @e IS NOT NULL;
UPDATE catalog_product_entity_text SET value = REPLACE(value, '<p>In “AI Generated NFT To Drive Business Growth,” Shahul teaches the technical and strategic aspects of NFT deployment—covering blockchain architecture, minting protocols, and marketplace operations. His sessions focus on the business implications of NFT adoption, including intellectual property management and monetization strategies. By combining blockchain expertise with real-world commercial insight, he equips learners to leverage NFTs and AI as transformative tools for business innovation.</p>', '<p>In “Autonomous AI Agents with OpenClaw,” Shahul teaches the technical and strategic aspects of agent deployment—covering agent architecture, tool and API integration, and multi-agent coordination. His sessions focus on the business implications of agentic AI adoption, including least-privilege access, audit trails, and defence against prompt injection. By combining his integration expertise with real-world commercial insight, he equips learners to leverage autonomous AI agents as transformative tools for business innovation.</p>')
  WHERE entity_id = @e AND attribute_id = @a_tp AND @e IS NOT NULL;
UPDATE catalog_product_entity_text SET value = REPLACE(value, '<p>In “AI Generated NFT To Drive Business Growth,” Shanique focuses on helping participants blend creative design with AI and blockchain technologies to create impactful digital products. Her sessions cover AI art generation, visual storytelling for NFT collections, and digital marketing strategies for NFT launches. With her artistic and technical expertise, she enables learners to use NFTs not just as collectibles, but as powerful brand engagement tools that open new opportunities in the digital economy.</p>', '<p>In “Autonomous AI Agents with OpenClaw,” Shanique focuses on helping participants apply AI agents to marketing, content creation, and customer engagement workflows. Her sessions cover agent-assisted content production, campaign reporting, and human-in-the-loop review of agent outputs. With her creative and technical expertise, she enables learners to use autonomous AI agents not just as automation tools, but as practical drivers of engagement and growth in the digital economy.</p>')
  WHERE entity_id = @e AND attribute_id = @a_tp AND @e IS NOT NULL;

-- ---------------------------------------------------------------- 9. search redirects
-- Anchor on the FULL old filename so sibling courses sharing the stem
-- (C1434 build-autonomous-ai-agent-with-openclaw, TGS-2025054471 autonomous-ai-agents,
-- C691 business-transformation-with-openclaw-digital-employees) are NOT hijacked.
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/wsq-business-transformation-with-openclaw-and-nft.html', '/wsq-autonomous-ai-agents-with-openclaw.html')
  WHERE redirect LIKE '%/wsq-business-transformation-with-openclaw-and-nft.html%';

-- Categories verified correct already (196 WSQ Agentic AI, 415 AI Agents Series,
-- 252 AI Courses, 325 WSQ AI Courses) - no category surgery needed.
-- prerequisite + funding/certification/skills_framework blocks verified clean of
-- NFT/blockchain terms - deliberately untouched.
