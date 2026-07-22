-- 669: Repurpose WSQ course TGS-2026061312
--   "WSQ - Optimizing Generative AI for Real World Deployments"
--   -> "WSQ - Claude Certified Architect Foundation"
-- SG-only in effect: TGS- SKUs do not exist on partner sites, so @e is NULL
-- there and every statement below is a guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026061312');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- Name + labels + cover
UPDATE catalog_product_entity_varchar SET value = 'WSQ - Claude Certified Architect Foundation'
  WHERE entity_id = @e AND attribute_id = @a_name AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'WSQ - Claude Certified Architect Foundation'
  WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026061312-20260722-150249.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label (product-page zoom gallery alt/title)
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'WSQ - Claude Certified Architect Foundation'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope (Catalog URL Rewrites indexer regenerates)
UPDATE catalog_product_entity_varchar SET value = 'wsq-claude-certified-architect-foundation'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta
UPDATE catalog_product_entity_varchar SET value = 'WSQ Claude Certified Architect Foundation | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'Design, build, and deploy Claude-powered AI applications with prompt engineering, MCP, AI agents, and RAG. Enjoy up to 70% WSQ funding subsidy.'
  WHERE entity_id = @e AND attribute_id = @a_md AND store_id = 0;
UPDATE catalog_product_entity_text SET value = 'WSQ Claude course, Claude Certified Architect Foundation, Anthropic Claude training Singapore, Claude AI architecture course, prompt engineering course, Model Context Protocol MCP, AI agents course, RAG training, enterprise AI architecture, Claude API development'
  WHERE entity_id = @e AND attribute_id = @a_mk AND store_id = 0;

-- Course outline (description)
UPDATE catalog_product_entity_text SET value = CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: Foundations of Claude AI Architecture","subsecs":[],"links":[]},{"title":"Topic 2: Building Claude-Powered AI Applications","subsecs":[],"links":[]},{"title":"Topic 3: AI Agents and Enterprise Integration","subsecs":[],"links":[]},{"title":"Topic 4: Deploying Production-Ready AI Solutions","subsecs":[],"links":[]}] -->', '\n',
'<p><strong>Topic 1: Foundations of Claude AI Architecture</strong></p>', '\n',
'<p><strong>Topic 2: Building Claude-Powered AI Applications</strong></p>', '\n',
'<p><strong>Topic 3: AI Agents and Enterprise Integration</strong></p>', '\n',
'<p><strong>Topic 4: Deploying Production-Ready AI Solutions</strong></p>')
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;

-- About This Course (short_description): replace the intro paragraphs, keep the
-- existing Course Brochure / Skills Framework / Certification / WSQ Funding
-- sections byte-identical by splicing at the Course Brochure heading.
UPDATE catalog_product_entity_text SET value = CONCAT(
'<p><strong>WSQ Claude Certified Architect Foundation</strong> equips learners with the knowledge and practical skills to design, build, and deploy AI applications using Anthropic''s Claude ecosystem. Participants will develop a strong foundation in large language models (LLMs), prompt engineering, context engineering, and AI solution architecture for building reliable, scalable, and secure enterprise applications.</p>', '\n',
'<p>Through hands-on labs, learners will explore Claude''s core capabilities, including long-context reasoning, structured outputs, artifacts, tool use, Model Context Protocol (MCP), and AI agent workflows. The course covers best practices for integrating external APIs, enterprise systems, and Retrieval-Augmented Generation (RAG) to create intelligent, context-aware applications.</p>', '\n',
'<p>Participants will learn how to design effective prompts, manage context and memory, evaluate AI performance, implement guardrails, reduce hallucinations, and optimize applications for accuracy, reliability, and cost. The course also introduces architecture patterns such as human-in-the-loop workflows, multi-agent collaboration, MCP integrations, security, governance, and responsible AI practices.</p>', '\n',
'<p>By the end of the course, learners will be able to architect Claude-powered AI solutions, integrate Claude with business systems and external tools, and apply industry best practices to build production-ready AI applications. This course is ideal for solution architects, software developers, AI engineers, technical consultants, and IT professionals seeking a solid foundation in enterprise AI architecture with Claude.</p>', '\n',
SUBSTRING(value, LOCATE('<h2>Course Brochure</h2>', value)))
  WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0
    AND LOCATE('<h2>Course Brochure</h2>', value) > 0;

-- Learning Outcomes cms_block
UPDATE cms_block SET content = CONCAT(
'<p>By end of the course, learners should be able to:</p>', '\n',
'<ul>', '\n',
'<li>LO1: Implement generative AI models using deep learning architectures matched to problem requirements and evaluate model suitability.</li>', '\n',
'<li>LO2: Apply deep learning concepts and optimisation techniques to preprocess generative-model datasets using embeddings and tokenisation, ensuring clean and structured inputs for effective neural network training.</li>', '\n',
'<li>LO3: Identify model training requirements and optimise performance by applying data-preprocessing, de-duplication, embeddings, and tokenisation techniques, as well as assessing training efficiency across parallel and cluster-based environments using benchmarks and metrics.</li>', '\n',
'<li>LO4: Train and refine generative models by evaluating weaknesses and applying targeted fine-tuning strategies.</li>', '\n',
'</ul>')
  WHERE identifier = 'course_TGS-2026061312_learning_outcomes';
