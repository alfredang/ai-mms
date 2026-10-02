-- C997 Business Transformation with AI Agents = the 2-day non-WSQ twin of TGS-2023037472 (WSQ - Business
-- Innovation with Agentic AI and AI Agents, (SG) WSQ-B17). The entity was recycled from the retired Google
-- Professional Machine Learning Engineer exam-prep course (4 days / 30 hrs / $1,200) and still carried its
-- leftovers. Courseware v1.0 converted from the WSQ v38 set
-- (github.com/tertiarycourses/C997-Business-Transformation-with-AI-Agents).
--
-- 1. Course fee $1,200 -> $700 (every scope row), Duration 30 -> 15 hrs, Sessions 4 -> 2.
-- 2. "What's This Course About" + course topics copied from the parent (store 0; no WSQ wording, no day count).
--    The old About opened "This WSQ AI Agents for Business course...". Store-scope overrides removed.
-- 3. Job Roles (whoshouldattend): the Google ML Engineer roles replaced by the parent's.
-- 4. Prerequisite: "Software: TBD" -> the courseware's tools.
-- 5. Funding block repointed from "WSQ - Autonomous AI Agents" to the WSQ twin
--    https://www.tertiarycourses.com.sg/wsq-business-innovation-with-agentic-ai-and-ai-agents.html (returns 200).
-- 6. The retired course's Kryterion certification-exam block is deactivated (this course has no exam).
-- Name / slug unchanged. Schedule template D02 -> B17 is a code path (CoursesaveController), not SQL.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: price + flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C997' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023037472' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_price  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');
SET @a_short  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

-- ------------------------------------------------------------ fee / duration / sessions -----
INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @pid, 700 FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_decimal SET value = 700
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '15' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '2' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_dur, @a_sess) AND store_id <> 0;

-- ---------------------------------------- About + topics + job roles from the parent -----
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_who) AND store_id <> 0;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, pt.attribute_id, 0, @pid, pt.value
  FROM catalog_product_entity_text pt
 WHERE @ok AND pt.entity_id = @src AND pt.store_id = 0
   AND pt.attribute_id IN (@a_short, @a_desc, @a_who)
   AND pt.value IS NOT NULL AND pt.value <> ''
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------- entry + software/hardware requirement -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<p>Target Age Group: 18-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong> free accounts on the following platforms (all have a free tier):</p>\n<ul>\n<li>ChatGPT, Google Gemini or Claude, and Microsoft Copilot</li>\n<li>Perplexity and Google NotebookLM</li>\n<li>ElevenLabs, Suno, Kling AI and CapCut</li>\n<li>Gamma and Canva</li>\n<li>n8n (cloud trial)</li>\n</ul>\n<p><strong>Hardware:</strong>&nbsp;Windows or Mac laptop with a modern web browser (Chrome or Edge)</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_prereq AND store_id <> 0;

-- ------------------------------------------------------------- funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C997 - Funding and Grant', 'course_C997_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C997_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C997_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C997_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2> <p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-business-innovation-with-agentic-ai-and-ai-agents.html" title="WSQ - Business Innovation with Agentic AI and AI Agents">WSQ - Business Innovation with Agentic AI and AI Agents</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C997_funding_and_grant';

-- ------------------------------------------ retired Google exam-prep block -----
UPDATE cms_block
   SET is_active = 0,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C997_certification_exam' AND content LIKE '%Kryterion%';
