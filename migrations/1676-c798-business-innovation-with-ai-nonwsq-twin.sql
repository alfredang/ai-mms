-- C798 "Business Innovation with AI": the 1-day non-WSQ twin of TGS-2026064716
-- (CASL - Business Innovation with Artificial Intelligence). The entity was recycled from the retired
-- "Pearson Vue Certified IT Specialist Artificial Intelligence" course and still carried its copy.
--
-- 1. Fee / Duration / Sessions: $700 / 15 hrs / 2 -> $350 / 7.5 hrs / 1.
-- 2. "What's This Course About" and course topics copied from the parent (its 4 About paragraphs and
--    5 topics), as ASCII literals. Neither states a day count.
-- 3. meta_description / meta_keyword rewritten from the parent (no Pearson, no day count); the orphan
--    TEXT-table meta_description that shadows the varchar value is deleted.
-- 4. Cover alt / gallery labels: the Pearson Vue title -> the course title.
-- 5. Funding block: "No funding" pointing at the funded CASL twin.
-- 6. The retired course's Pearson Vue certification-exam block is deactivated (this course has no exam).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Schedule template B11 (gid 132) -> A03 (gid 175, counterpart of the parent's (SG) WSQ-A03) is switched
-- on prod via the code path, not here.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C798' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064716' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @title := 'Business Innovation with AI';

SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');

-- ------------------------------------------- fee / duration / sessions -----
INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @pid, 350
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '7.5'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '1'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @title
 WHERE @ok AND g.entity_id = @pid;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Drive business innovation with generative AI, agentic AI and AI agents. Explore n8n, Claude Code and Codex use cases, weigh costs and benefits, and implement AI-driven initiatives with governance and human oversight.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Orphan TEXT-table meta_description shadows the varchar value on render.
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Business Innovation with AI, AI for Business, Generative AI, Agentic AI, AI Agents, n8n, Claude Code, Codex, Claude Cowork, Digital Workers, AI Strategy, AI Implementation, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course equips participants with the knowledge and practical skills to drive business innovation using generative AI, agentic AI and autonomous AI agents. Participants will examine the evolution of artificial intelligence from 2023 to 2026&mdash;from generative AI and prompt engineering to agentic AI, context engineering, harness engineering and AI-powered digital workers.</p><p>Participants will learn how AI is transforming traditional business models, operating processes and customer experiences. The course introduces key AI agent capabilities, including reasoning, memory, tool use, skills, workflow execution and human&ndash;AI collaboration. It also explains loop engineering, where agents repeatedly plan, act, observe, evaluate and improve their actions to accomplish complex business objectives.</p><p>Through practical demonstrations and real-world use cases, participants will explore technologies such as n8n, Claude Code, Codex, OpenClaw, Hermes Agent and Paperclip. They will examine how these technologies support automated workflows, multi-agent coordination, digital workers and natural-language interfaces for operating software and business systems. Applications involving Claude Cowork, ChatGPT for Work and n8n will demonstrate how agentic AI can improve administration, marketing, sales, customer service and operations.</p><p>Participants will identify potential AI opportunities, compare traditional and AI-enabled business models, and evaluate the costs, benefits, risks and feasibility of adoption. By the end of the course, they will be able to design and implement an AI-driven business innovation initiative supported by appropriate governance, human oversight and continuous improvement.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: Evolution of Business AI from Generative AI to Autonomous AI Agents</h3>\n<h3 class="course-topic-h3">Topic 2: Generative AI, Agentic AI and AI Agent Technologies</h3>\n<h3 class="course-topic-h3">Topic 3: Context, Harness and Loop Engineering for AI Agents</h3>\n<h3 class="course-topic-h3">Topic 4: Business Opportunities and Innovative Agentic AI Use Cases</h3>\n<h3 class="course-topic-h3">Topic 5: Evaluating and Implementing AI-Driven Business Innovation</h3>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_mdesc, @a_dur, @a_sess) AND store_id <> 0;

DELETE FROM catalog_product_entity_decimal
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C798 - Funding and Grant', 'course_C798_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C798_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C798_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C798_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For CASL funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-business-innovation-with-artificial-intelligence.html" title="CASL - Business Innovation with Artificial Intelligence">CASL - Business Innovation with Artificial Intelligence</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C798_funding_and_grant';

-- -------------------------------------- retired Pearson exam block -----
UPDATE cms_block
   SET is_active = 0,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C798_certification_exam' AND content LIKE '%Pearson Vue%';
