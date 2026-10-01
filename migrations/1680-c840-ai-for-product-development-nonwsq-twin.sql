-- C840 AI for Product Development = the 2-day non-WSQ twin of TGS-2024045799 (WSQ - Agentic AI for Product
-- Development). The entity was recycled from the retired DP-100 Azure Data Scientist Associate Exam Prep course
-- (earlier still Deep Learning with PyTorch) and still carried its copy. Courseware v1.0 converted from the WSQ v7.0 set.
--
-- 1. "What's This Course About", course topics and "Who should attend" copied from the parent (ASCII literals
--    copied from prod; none states a day count or WSQ).
-- 2. Prerequisite: the stale PyTorch / PyCharm block -> the standard non-WSQ entry requirement + this course's software.
-- 3. meta_description / meta_keyword rewritten (no DP-100, no WSQ funding claim, no day count); the orphan
--    TEXT-table meta_description that shadows the varchar value is deleted.
-- 4. Cover alt / gallery labels: the DP-100 title -> the course title.
-- 5. Funding block points at the WSQ twin (was the DP-100 WSQ course).
-- 6. The retired course's Pearson Vue / DP-100 certification-exam block is deactivated (this course has no exam).
-- Name / slug / fee / duration / sessions are already AI for Product Development / ai-for-product-development /
-- $700 / 15 / 2 -> unchanged. Schedule template B11 -> B19 (counterpart of the parent's (SG) WSQ-B19) is switched
-- on prod via the code path, not here.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C840' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024045799' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @title := 'AI for Product Development';

SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

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
SELECT 4, @a_mdesc, 0, @pid, 'Apply agentic AI across the product development lifecycle: evaluate AI builders, design multi-agent workflows, prototype with evaluation sets and recommend a governed deployment at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;

-- Orphan TEXT-table meta_description shadows the varchar value on render.
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'AI for product development, AI product management course, multi-agent workflows, autonomous AI agents, AI product research, AI prototyping, agentic AI builders, AI product roadmap, AI user personas, agentic AI course Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------- About + topics + who should attend from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course equips participants with practical skills to apply agentic AI across the product development lifecycle, from opportunity discovery and concept creation to prototyping, testing, launch, and continuous improvement. Learners will explore how autonomous AI agents can perform multi-step tasks, coordinate workflows, analyse information, and support product teams in making faster, evidence-based decisions.</p><p>Participants will use agentic AI to conduct market and competitor research, identify customer needs, develop user personas, generate product concepts, and prioritise features. They will learn to translate product ideas into requirements, user stories, journey maps, specifications, development plans, and prototypes that align with business objectives and user expectations.</p><p>The course also covers designing multi-agent workflows for coordinating research, design, development, documentation, quality assurance, and stakeholder feedback. Learners will apply agentic AI to evaluate prototypes, analyse user feedback, detect product gaps, monitor key performance indicators, and recommend improvements throughout iterative development cycles.</p><p>Emphasis is placed on human oversight, data quality, responsible AI practices, security, governance, and the validation of AI-generated outputs. Through hands-on projects, participants will develop an AI-assisted product concept and supporting development workflow. By the end of the course, learners will be able to use agentic AI to improve collaboration, reduce repetitive work, shorten development cycles, and create products that better address customer and market needs.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Evaluating Agentic AI Tools for Product Research and Development","subsecs":[]},{"title":"Topic 2: Building and Optimising Agentic AI Product Development Workflows","subsecs":[]},{"title":"Topic 3: Deploying and Evaluating Agentic AI-Powered Product Solutions","subsecs":[]}] -->\r\n<p><strong>Topic 1: Evaluating Agentic AI Tools for Product Research and Development</strong></p>\r\n<p><strong>Topic 2: Building and Optimising Agentic AI Product Development Workflows</strong></p>\r\n<p><strong>Topic 3: Deploying and Evaluating Agentic AI-Powered Product Solutions</strong></p>\r\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul><li>Product Manager</li><li>Product Owner</li><li>AI Product Manager</li><li>Product Development Engineer</li><li>Digital Product Manager</li><li>UX/UI Designer</li><li>User Researcher</li><li>AI Implementation Consultant</li><li>Product Marketing Manager</li><li>Solution Architect</li><li>Web Developer</li><li>Data Analyst</li><li>Software Engineer</li><li>Business Analyst</li><li>Innovation Manager</li><li>Project Manager</li><li>AI Researcher</li><li>Customer Insights Analyst</li><li>Quality Assurance Engineer</li><li>R&amp;D Manager</li></ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------- entry + software/hardware requirement -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<p>Target Age Group: 21-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<p>You can download and install the following software:</p>\n<ul>\n<li>An agentic AI builder or assistant (Claude, ChatGPT or Microsoft Copilot &mdash; the free tier is sufficient)</li>\n<li><span style="text-decoration: underline;"><a href="https://www.python.org/downloads/" target="_blank">Python 3</a></span> (to run the activity verifiers)</li>\n<li><span style="text-decoration: underline;"><a href="https://code.visualstudio.com/download" target="_blank">Visual Studio Code</a></span> or another text editor for YAML, JSON and Markdown files</li>\n<li>A spreadsheet (Excel, Numbers or Google Sheets)</li>\n</ul>\n<p><strong>Hardware:</strong> Windows or Mac laptop with administrator rights to install software</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_who, @a_prereq, @a_mkey) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C840 - Funding and Grant', 'course_C840_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C840_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C840_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C840_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-product-development.html" title="WSQ - Agentic AI for Product Development">WSQ - Agentic AI for Product Development</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C840_funding_and_grant';

-- ------------------------------------- retired Pearson exam block -----
UPDATE cms_block
   SET is_active = 0,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C840_certification_exam' AND content LIKE '%Pearson Vue%';
