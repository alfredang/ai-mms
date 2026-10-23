-- C991: "Build Multi Agent Systems with ADK, Streamlit, Autogen and CrewAI"
--    -> "Claude Certified Associate - Foundations (CCAO-F) Exam Prep".
--
-- Content follows the official CCAO-F exam guide v1.0 (effective July 2026), as condensed at
-- github.com/Amey-Thakur/CLAUDE-CERTIFICATIONS/associate-foundations: the 7 topics ARE the 7 exam
-- domains, in exam-guide order.
--
-- 1. name, url_key/url_path (build-multi-agent-systems-with-adk-streamlit-autogen-and-crewai ->
--    claude-certified-associate-foundations-ccao-f-exam-prep), cover alt + gallery labels, metas,
--    level -> Beginner, new cover PNG on R2 (the PNG bakes the title).
-- 2. About / topics / Job Roles / keywords rewritten; Dr. Alfred Ang's bio rewritten for CCAO-F (the
--    only trainer in mmd_product_trainer -- the other two blob bios described the multi-agent course).
-- 3. prerequisite: same entry requirement, software list Python/VS Code/Gemini -> Claude Pro.
-- 4. Funding block: the WSQ multi-agent cross-link is dropped (no WSQ CCAO-F course exists).
--    New course_C991_certification_exam block (exam registration on the Anthropic Partner Academy).
-- 5. atc_partners = claude_partner_network -> "Claude Partner Network" card on the page.
-- 6. Categories: out of "Multi AI Agents Series", into "Claude Certification Exam Prep" (after C437,
--    alphabetical), mirrored into catalog_category_product_index.
-- 7. Upsells: multi-agent WSQ courses -> Claude courses.
-- 8. 301s: system rows renamed in place to the new slug. Every OLD path of C991 (and its legacy
--    aliases) 301s one hop to the live multi-agent WSQ twin TGS-2025059028, which teaches what those
--    URLs promised. The old CCAO-F slug from C744's previous life (now 301ing to Claude Design for
--    UX/UI) is repointed here -- same exam.
-- 9. Search: C991/c0991 + CCAO-F queries -> new slug; c744/c0744 -> C744's own page directly (they
--    2-hopped through the CCAO-F slug repointed in 8).
-- Fee / duration / sessions unchanged. Schedule template unchanged (no WSQ twin any more).
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent. Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C991' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @old_title := 'Build Multi Agent Systems with ADK, Streamlit, Autogen and CrewAI';
SET @new_title := 'Claude Certified Associate - Foundations (CCAO-F) Exam Prep';
SET @old_slug  := 'build-multi-agent-systems-with-adk-streamlit-autogen-and-crewai';
SET @new_slug  := 'claude-certified-associate-foundations-ccao-f-exam-prep';
SET @twin_slug := 'wsq-build-and-deploy-agentic-ai-apps-with-crewai-autogen-adk-and-streamlit';
SET @ccaof_old := 'claude-certified-associate-foundations-certification';
SET @base      := 'https://www.tertiarycourses.com.sg/';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_trainer := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_atc     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'atc_partners');
SET @a_level   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'level');
SET @o_beg     := (SELECT o.option_id FROM eav_attribute_option o
                     JOIN eav_attribute_option_value ov ON ov.option_id = o.option_id AND ov.store_id = 0
                    WHERE o.attribute_id = @a_level AND ov.value = 'Beginner' LIMIT 1);

-- ------------------------------------------------------------ name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ----------------------------------------------------------- image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @new_title
 WHERE @ok AND v.entity_id = @pid AND v.value = @old_title;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid AND gv.label = @old_title;

-- ------------------------------------------------------- meta + cover -----
-- meta_title stored BARE (MMD_Seotitle appends the brand at render time).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description is varchar(255).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid,
       'Prepare for the Claude Certified Associate - Foundations (CCAO-F) exam. Cover all 7 exam domains, from prompting and output validation to governance and troubleshooting, with hands-on Claude practice.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C991-20261023-163141.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_level, 0, @pid, @o_beg FROM DUAL WHERE @ok AND @o_beg IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ text content -----
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND store_id <> 0
   AND attribute_id IN (@a_short, @a_desc, @a_who, @a_mkey, @a_trainer, @a_prereq, @a_atc);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid,
       'Claude Certified Associate, CCAO-F, Claude Certified Associate Foundations, Claude Certification, Anthropic Certification, Claude Exam Prep, Claude Partner Network, Claude Projects, Prompt Engineering, AI Certification, Generative AI'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- What's This Course About
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Claude Certified Associate - Foundations (CCAO-F) Exam Prep prepares you for the Claude Certified Associate - Foundations exam from Anthropic, which validates that you can apply Claude to complete real-world business and productivity tasks with minimal guidance. The certification is intended for professionals who use Claude as a productivity tool in roles such as operations, marketing, project management, education, communications and consulting &ndash; people who translate business objectives into effective Claude interactions, evaluate generated content critically and know when human review or escalation is required.</p><p>The course follows the seven official exam domains. You will start with prompting and task execution, then focus on output evaluation and validation, the most heavily weighted domain, where you learn to check outputs for accuracy and completeness, spot hallucinations and bias, and decide when human review is needed. You will then compare Claude product features and the Haiku, Sonnet and Opus models, integrate Claude into existing workflows, and configure Claude Projects with instructions, knowledge sources and connectors.</p><p>The course closes with governance, risk and responsible use, including data sensitivity and organisational AI policy, and with troubleshooting and optimising underperforming prompts and workflows. Each domain combines explanation, hands-on practice in Claude and exam-style scenario questions. The CCAO-F exam has 60 multiple-choice and multiple-response questions in 120 minutes, delivered by Pearson VUE online or at a test centre, with a passing scaled score of 720 out of 1,000. By the end, you will be able to apply Claude confidently at work and be well prepared to pass the exam.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Course outline: the 7 exam domains (LSN_DATA marker = the admin topic editor's source)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title": "Topic 1: Prompting and Task Execution", "subsecs": []}, {"title": "Topic 2: Output Evaluation and Validation", "subsecs": []}, {"title": "Topic 3: Product and Model Selection", "subsecs": []}, {"title": "Topic 4: Workflow Integration and Solution Design", "subsecs": []}, {"title": "Topic 5: Configuration and Knowledge Management", "subsecs": []}, {"title": "Topic 6: Governance, Risk, and Responsible Use", "subsecs": []}, {"title": "Topic 7: Troubleshooting and Optimization", "subsecs": []}] -->
<p><strong>Topic 1: Prompting and Task Execution</strong></p>
<p><strong>Topic 2: Output Evaluation and Validation</strong></p>
<p><strong>Topic 3: Product and Model Selection</strong></p>
<p><strong>Topic 4: Workflow Integration and Solution Design</strong></p>
<p><strong>Topic 5: Configuration and Knowledge Management</strong></p>
<p><strong>Topic 6: Governance, Risk, and Responsible Use</strong></p>
<p><strong>Topic 7: Troubleshooting and Optimization</strong></p>
'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Job Roles
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul><li>Operations Manager</li><li>Operations Executive</li><li>Marketing Manager</li><li>Marketing Executive</li><li>Project Manager</li><li>Business Analyst</li><li>Management Consultant</li><li>Corporate Communications Executive</li><li>Communications Specialist</li><li>Educator</li><li>Corporate Trainer</li><li>Human Resource Executive</li><li>Administrative Executive</li><li>Content Specialist</li><li>Customer Service Manager</li><li>Knowledge Management Specialist</li><li>Digital Transformation Lead</li><li>AI Adoption Champion</li></ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Entry requirement unchanged; software list -> Claude. (C991's prerequisite holds nothing else.)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Minimum Entry Requirement</h2>
<p>Knowledge and Skills</p>
<ul>
<li>Able to operate using computer functions</li>
<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>
</ul>
<p>Attitude</p>
<ul>
<li>Positive Learning Attitude</li>
<li>Enthusiastic Learner</li>
</ul>
<p>Experience</p>
<ul>
<li>Minimum of 1 year of working experience.</li>
</ul>
<p>Target Age Group: 18-65 years old</p>
<h2>Minimum Software/Hardware Requirement</h2>
<p><strong>Software:</strong></p>
<p>You will need the following for this course:</p>
<ul>
<li><a href="https://claude.ai/" target="_blank">A Claude Pro (or higher) subscription</a> &ndash; required</li>
<li><a href="https://claude.ai/download" target="_blank">Claude desktop app</a> &ndash; free download (optional, the web app also works)</li>
</ul>
<p><strong>Hardware:</strong> Windows PC or Mac laptop</p>
'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Trainer bio (Dr. Alfred Ang is the only trainer assigned in mmd_product_trainer).
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_trainer, 0, @pid, '<p dir="ltr"><strong data-course-bio>Dr. Alfred Ang:</strong> Dr. Alfred Ang uses Claude across the operations, marketing and courseware work of a training organisation, which is exactly the kind of practical, business-focused use the Claude Certified Associate - Foundations exam sets out to test. He serves as Managing Director, CIO, CTO and Chief Instructional Designer of Tertiary Infotech Academy Pte Ltd, having founded Tertiary Courses, and he is a full-stack AI developer and Agentic AI solution architect. Much of his recent public work is built on Anthropic&#x27;s platform, including a WSQ courseware generation platform built with the Claude Agent SDK, an AI-powered CMS whose chatbot and auto-blog scheduler run on the Claude Agent SDK, and published Claude Code skill collections for courseware production. His credentials include a PhD in Electrical Engineering from NUS, an MSc in Electrical and Electronic Engineering from NTU, a B.Sc (Hons) in Physics from NUS, Microsoft Certified AI Engineer Associate (AI-102), AWS Certified Solutions Architect and AI Practitioner, and a Certificate in AI Ethics and Governance (Senior Professional) from NTU. He has published more than 20 peer-reviewed papers and co-invented more than 20 US patents.

This exam prep course follows the seven official CCAO-F exam domains, and Dr. Ang teaches each one through the everyday business tasks where Claude adds value. Learners start with prompting and task execution, then spend the most time on output evaluation and validation, practising how to verify claims against authoritative sources, spot hallucinations and decide when a human must review the result. He then compares Claude Projects, research mode and Artifacts, and the Haiku, Sonnet and Opus models, so learners can match the model tier to the task rather than defaulting to the largest one. Workflow integration and the configuration of Projects with instructions, knowledge sources and connectors follow, and the course closes with governance, risk and responsible use, such as anonymising regulated data before upload, and with troubleshooting prompts and workflows that underperform. Throughout, he frames practice the way the exam does, with scenario questions that reward applied judgement over recall. As an ACTA-certified trainer and DACE-certified curriculum developer, he blends exam-style practice with hands-on work in Claude, so learners prepare for the credential while gaining skills they can use at work the next day. To see the Claude-based systems he builds, visit his GitHub portfolio at https://github.com/alfredang and connect with him on LinkedIn at https://www.linkedin.com/in/angchewhoe/</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Claude Partner Network accreditation card (vocab in MMD_CourseImage_Helper_Data::getAtcPartners)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_atc, 0, @pid, 'claude_partner_network' FROM DUAL WHERE @ok AND @a_atc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------------ cms blocks -----
UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p>', is_active = 1, update_time = NOW()
 WHERE @ok AND identifier = 'course_C991_funding_and_grant';

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C991 - Certification Exam', 'course_C991_certification_exam', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C991_certification_exam');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE @ok AND identifier = 'course_C991_certification_exam';

UPDATE cms_block
   SET content = '<p>Once you are prepared, you can register for the <strong>Claude Certified Associate - Foundations (CCAO-F)</strong> exam on the <span style="text-decoration: underline;"><a href="https://anthropic-partners.skilljar.com/claude-certified-associate-foundations-certification" title="Claude Certified Associate - Foundations Certification" target="_blank">Anthropic Partner Academy</a></span>. Registration requires a company email address recognised in the Claude Partner Network. The exam is delivered by Pearson VUE, online proctored or at a test centre, and the certification is valid for 12 months. Note that the course fee does not include the certification exam fee.</p>',
       is_active = 1, update_time = NOW()
 WHERE @ok AND identifier = 'course_C991_certification_exam';

-- ------------------------------------------------------------- categories -----
SET @a_cname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @c_multi := (SELECT entity_id FROM catalog_category_entity_varchar
                  WHERE attribute_id = @a_cname AND store_id = 0 AND value = 'Multi AI Agents Series' LIMIT 1);
SET @c_claude := (SELECT entity_id FROM catalog_category_entity_varchar
                   WHERE attribute_id = @a_cname AND store_id = 0 AND value = 'Claude Certification Exam Prep' LIMIT 1);
SET @c_parent := (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @c_claude);
SET @c_pos := (SELECT COALESCE(MAX(position), 0) + 1 FROM catalog_category_product
                WHERE category_id = @c_claude AND product_id <> @pid);

DELETE FROM catalog_category_product       WHERE @ok AND product_id = @pid AND category_id = @c_multi;
DELETE FROM catalog_category_product_index WHERE @ok AND product_id = @pid AND category_id = @c_multi;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @c_claude, @pid, @c_pos FROM DUAL WHERE @ok AND @c_claude IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_claude, @pid, @c_pos, 1, 1, 4 FROM DUAL WHERE @ok AND @c_claude IS NOT NULL;

-- the anchor parent ("Certification Exam Prep") lists it through the child
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_parent, @pid, @c_pos, 0, 1, 4 FROM DUAL WHERE @ok AND @c_claude IS NOT NULL AND @c_parent > 2;

-- ---------------------------------------------------------------- upsells -----
DELETE FROM catalog_product_link WHERE @ok AND product_id = @pid AND link_type_id IN (1, 4);

INSERT IGNORE INTO catalog_product_link (product_id, linked_product_id, link_type_id)
SELECT @pid, p.entity_id, 4
  FROM catalog_product_entity p
 WHERE @ok AND TRIM(p.sku) IN ('C437', 'TGS-2026061312', 'C1382', 'TGS-2025052468', 'C197', 'TGS-2023018659');

INSERT IGNORE INTO catalog_product_link_attribute_int (product_link_attribute_id, link_id, value)
SELECT a.product_link_attribute_id, l.link_id,
       FIELD(TRIM(p.sku), 'C437', 'TGS-2026061312', 'C1382', 'TGS-2025052468', 'C197', 'TGS-2023018659')
  FROM catalog_product_link l
  JOIN catalog_product_entity p ON p.entity_id = l.linked_product_id
  JOIN catalog_product_link_attribute a
    ON a.link_type_id = l.link_type_id AND a.product_link_attribute_code = 'position'
 WHERE @ok AND l.product_id = @pid AND l.link_type_id = 4;

-- ------------------------------------------------------------ 301 rewrites -----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c991_old;
CREATE TEMPORARY TABLE tmp_c991_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c991_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) The Multi AI Agents Series path goes away with the category; rename the rest in place so the
--    new slug resolves without a rewrite refresh.
DELETE FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1 AND category_id = @c_multi;

UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 3) Legacy aliases that pointed at any old-slug path -> the multi-agent WSQ twin (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@twin_slug, '.html'), product_id = NULL
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Every old path of C991 -> the multi-agent WSQ twin.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@twin_slug, '.html'), 0, 'RP'
  FROM tmp_c991_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c991_old;

-- 5) The old CCAO-F slug (C744's previous life) -> this course. Fresh id_path so it no longer
--    squats C744's 'product/744'.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html'), product_id = NULL,
       id_path = CONCAT('manual-301-', MD5(request_path), '-', store_id)
 WHERE @ok AND store_id = 1 AND is_system = 0 AND options = 'RP'
   AND (request_path = CONCAT(@ccaof_old, '.html') OR request_path LIKE CONCAT('%/', @ccaof_old, '.html'));

-- -------------------------------------------------------- search redirects -----
UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, @new_slug, '.html')
 WHERE @ok AND store_id = 1 AND query_text IN ('C991', 'c0991');

UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, 'claude-design-for-ux-ui.html')
 WHERE @ok AND store_id = 1 AND query_text IN ('C744', 'c0744')
   AND redirect = CONCAT(@base, @ccaof_old, '.html');

UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, @new_slug, '.html')
 WHERE @ok AND store_id = 1 AND (redirect IS NULL OR redirect = '')
   AND query_text IN ('claude certified associate', 'Claude associate',
                      'Claude Certified Associate - Foundations Certification', 'CCAO-F', 'ccaof');
