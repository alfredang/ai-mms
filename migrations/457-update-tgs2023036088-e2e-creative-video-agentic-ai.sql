-- Update WSQ course TGS-2023036088 from "WSQ - Automate Creative Video
-- Editing with Agentic AI Workflows and n8n" to "WSQ - End to End Creative
-- Video Creation with Agentic AI and Vibe Coding": name, topics
-- (description), overview (short_description), meta title/description/
-- keywords, url_key, plus a custom 301 from the old URL so external links
-- (MySkillsFuture, ads) keep working. Learning outcomes block unchanged
-- (new LOs are identical). Partner-safe: TGS- SKUs exist only on SG, so @e
-- is NULL on MY/GH and every statement is a no-op. Store scope 0; per-store
-- overrides of the rewritten attributes are cleared. Idempotent. No content
-- line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='TGS-2023036088');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'WSQ - End to End Creative Video Creation with Agentic AI and Vibe Coding' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>This course equips media professionals, content creators, marketers, and digital storytellers with the skills to create professional-quality videos using Agentic AI and vibe coding methodologies. Participants will learn how to design, build, and manage end-to-end AI-powered video creation workflows, from content ideation to final video publishing.</p>
<p>The course covers the complete creative video production lifecycle, including idea generation, script writing, storyboard development, voiceover creation, image and video asset generation, video editing, post-production, quality assurance, and content distribution. Learners will explore how multiple AI agents can collaborate to automate and optimize different stages of the creative process while maintaining consistency, quality, and alignment with creative objectives.</p>
<p>A key focus of the course is the use of vibe coding techniques to rapidly develop and customize agentic workflows without extensive programming expertise. Participants will learn how to orchestrate AI agents, automate repetitive production tasks, improve creative efficiency, and scale content creation operations.</p>
<p>By the end of the course, participants will be able to design and manage AI-powered video production pipelines, evaluate and enhance creative outputs, integrate emerging AI technologies into their workflows, and efficiently produce high-quality video content using Agentic AI and vibe coding approaches.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: End-to-End Creative Video Production with Agentic AI and Vibe Coding</h3>
<ul>
<li>Define creative goals, content strategies, and video production workflows</li>
<li>Design and orchestrate AI-powered workflows for script writing, storyboarding, asset generation, voiceovers, editing, and publishing</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Video Review, Quality Assurance, and Optimization with Agentic AI</h3>
<ul>
<li>Review video content for storytelling effectiveness, brand consistency, and audience engagement</li>
<li>Use AI agents to automate quality checks, content validation, feedback collection, and optimization processes</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Enhancing Creative Workflows with Emerging Agentic AI Technologies</h3>
<ul>
<li>Apply improvements and enhancements using AI-powered creative workflows</li>
<li>Explore new Agentic AI tools, multimodal AI models, and vibe coding techniques for scalable video content creation</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'WSQ End to End Creative Video Creation with Agentic AI & Vibe Coding | Tertiary Courses Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Create professional videos end to end with Agentic AI and vibe coding - from scripting and storyboarding to editing, QA and publishing. Enjoy up to 70% WSQ funding subsidy.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'WSQ video creation course, agentic AI video production, vibe coding Singapore, AI video editing training, script writing storyboarding AI, AI voiceover generation, video quality assurance AI, WSQ funded media course, end to end video workflow' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'wsq-end-to-end-creative-video-creation-with-agentic-ai-and-vibe-coding' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE @e IS NOT NULL AND entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url);
DELETE FROM catalog_product_entity_text
WHERE @e IS NOT NULL AND entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Custom (is_system=0) 301 so the old URL keeps resolving after the
-- catalog_url reindex replaces the system rewrite. Survives reindexes.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, 'custom/tgs-2023036088-e2e-video-rename',
       'wsq-automate-creative-video-editing-with-agentic-ai-workflows-and-n8n.html',
       'wsq-end-to-end-creative-video-creation-with-agentic-ai-and-vibe-coding.html',
       0, 'RP', 'TGS-2023036088 rename to End to End Creative Video Creation with Agentic AI and Vibe Coding'
FROM core_store s WHERE s.store_id > 0 AND @e IS NOT NULL;
