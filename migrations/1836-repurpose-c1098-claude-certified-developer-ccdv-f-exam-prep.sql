-- C1098: "Google Cloud Certified Associate Cloud Engineer Training"
--    -> "Claude Certified Developer - Foundations (CCDV-F) Exam Prep".
--
-- Content follows the official CCDV-F Exam Guide v1.0 (effective July 2026; blueprint as published at
-- claudecertificationguide.com/ccdv-f): the 8 topics ARE the 8 exam domains, in exam-guide order
-- (14.7 / 33.1 / 3.1 / 2.6 / 16.8 / 11 / 8.1 / 10.6 %). Sibling of C991 CCAO-F (1833) / C437 CCAR-F (1834).
--
-- 1. name, url_key/url_path (google-associate-cloud-engineer-certification-exam-prep(-1761) ->
--    claude-certified-developer-foundations-ccdv-f-exam-prep), cover alt + gallery labels, metas
--    (meta_title stored BARE), level -> Intermediate, new cover PNG on R2 (the PNG bakes the title).
-- 2. About / topics / Job Roles / keywords rewritten. Trainer blob (GCP trainers) replaced with a CCDV-F
--    bio for Dr. Alfred Ang, who is added to the trainer pool (mmd_product_trainer) as on C991/C437.
-- 3. prerequisite: same entry requirement + programming knowledge; software list GCP -> Claude API,
--    Claude Code, Python/Node.js, VS Code.
-- 4. Funding block: the WSQ Google ACE cross-link is dropped (no WSQ CCDV-F course exists).
--    course_C1098_certification_exam: Kryterion/Google copy -> Anthropic Partner Academy registration.
-- 5. atc_partners = claude_partner_network -> "We are a member of the Claude Partner Network" card.
-- 6. Categories: out of Cloud Computing / Google Cloud / Google Certification Exam Prep / Google Cloud
--    Certification Prep; into Claude Certification Exam Prep (last, alphabetical) and AI Courses
--    (beside C437). All Courses / Infocomm Technology / Certification Exam Prep kept.
-- 7. Upsells: GCP / Azure WSQ courses -> Claude courses.
-- 8. 301s: system rows renamed in place to the new slug. Every OLD path of C1098 and all ~1,700 legacy
--    aliases that pointed at it 301 one hop to the live WSQ Google ACE twin TGS-2023041024, which
--    teaches what those URLs promised. Product 740's 8 rows that sent the bare ACE slug to the ML
--    Engineer course are repointed there too. The old CCDV-F slug from C439's previous life (now
--    301ing to Generative AI for Content Creation) is repointed here -- same exam.
-- 9. Search: c1098 + CCDV-F queries -> new slug; Google ACE queries -> WSQ twin; "google certification"
--    -> Google Certification Exam Prep category; c439/c0439 -> C439's own page directly (they 2-hopped
--    through the CCDV-F slug repointed in 8); unrelated rows that pointed here are cleared.
-- Fee / duration / sessions unchanged. Schedule template unchanged (no WSQ CCDV-F twin).
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent. Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1098' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @old_title := 'Google Cloud Certified Associate Cloud Engineer Training';
SET @new_title := 'Claude Certified Developer - Foundations (CCDV-F) Exam Prep';
SET @old_slug  := 'google-associate-cloud-engineer-certification-exam-prep';
SET @new_slug  := 'claude-certified-developer-foundations-ccdv-f-exam-prep';
SET @twin_slug := 'wsq-google-associate-cloud-engineer-training';
SET @ccdvf_old := 'claude-certified-developer-foundations-certification';
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
SET @o_int     := (SELECT o.option_id FROM eav_attribute_option o
                     JOIN eav_attribute_option_value ov ON ov.option_id = o.option_id AND ov.store_id = 0
                    WHERE o.attribute_id = @a_level AND ov.value = 'Intermediate' LIMIT 1);

-- ------------------------------------------------------------ name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey AND store_id = 0;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath AND store_id = 0;

-- store 1 url_path still held the suffixed old slug (-1761.html)
DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_urlkey, @a_urlpath) AND store_id <> 0;

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
       'Prepare for the Claude Certified Developer - Foundations (CCDV-F) exam. Cover all 8 exam domains, from the Claude API, Agent SDK and MCP servers to model selection, security and Claude Code.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1098-20261023-164625.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_level, 0, @pid, @o_int FROM DUAL WHERE @ok AND @o_int IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ text content -----
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND store_id <> 0
   AND attribute_id IN (@a_short, @a_desc, @a_who, @a_mkey, @a_trainer, @a_prereq, @a_atc);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid,
       'Claude Certified Developer, CCDV-F, Claude Certified Developer Foundations, Claude Certification, Anthropic Certification, Claude Exam Prep, Claude Partner Network, Claude API, Claude Agent SDK, Claude Code, MCP, AI Engineer Certification'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- What's This Course About
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Claude Certified Developer - Foundations (CCDV-F) Exam Prep prepares you for the Claude Certified Developer - Foundations exam from Anthropic, which validates that you can build, integrate and ship Claude-powered applications, agents and workflows. The certification is intended for AI engineers and software developers with one to five years of engineering experience and at least six months of hands-on work with Claude or comparable LLM systems, who are proficient in Python or TypeScript and comfortable with REST APIs and command-line tools.</p><p>The course follows the eight official exam domains and gives each one the time its exam weighting deserves. You will spend the most time on applications and integration, a third of the exam, covering Claude API mechanics, Claude application design, software engineering foundations, configuration management and the systems life cycle. You will then cover model selection and optimisation, including LLM fundamentals, model trade-offs and cost and token management, followed by building agents and workflows with the Claude Agent SDK, prompt and context engineering, and implementing tools and MCP servers.</p><p>The course closes with security and safety, including AI application security, guardrails, Claude hooks and secrets management, together with operating Claude Code and debugging and error handling. Each domain combines explanation, hands-on coding labs with the Claude API, Agent SDK and Claude Code, and exam-style scenario questions. The CCDV-F exam has 53 multiple-choice and multiple-response questions in 120 minutes, delivered by Pearson VUE online or at a test centre, with a passing scaled score of 720 out of 1,000. As a member of the Claude Partner Network, Tertiary Infotech Academy aligns this course with Anthropic&#x27;s official exam guide. By the end, you will be able to build production-ready Claude applications with confidence and be well prepared to pass the exam.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Course outline: the 8 exam domains (LSN_DATA marker = the admin topic editor's source)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title": "Topic 1: Agents and Workflows", "subsecs": []}, {"title": "Topic 2: Applications and Integration", "subsecs": []}, {"title": "Topic 3: Claude Code", "subsecs": []}, {"title": "Topic 4: Eval, Testing, and Debugging", "subsecs": []}, {"title": "Topic 5: Model Selection and Optimisation", "subsecs": []}, {"title": "Topic 6: Prompt and Context Engineering", "subsecs": []}, {"title": "Topic 7: Security and Safety", "subsecs": []}, {"title": "Topic 8: Tools and MCPs", "subsecs": []}] -->
<p><strong>Topic 1: Agents and Workflows</strong></p>
<p><strong>Topic 2: Applications and Integration</strong></p>
<p><strong>Topic 3: Claude Code</strong></p>
<p><strong>Topic 4: Eval, Testing, and Debugging</strong></p>
<p><strong>Topic 5: Model Selection and Optimisation</strong></p>
<p><strong>Topic 6: Prompt and Context Engineering</strong></p>
<p><strong>Topic 7: Security and Safety</strong></p>
<p><strong>Topic 8: Tools and MCPs</strong></p>
'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Job Roles
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul><li>AI Engineer</li><li>Software Developer</li><li>Software Engineer</li><li>Backend Developer</li><li>Full-Stack Developer</li><li>Application Developer</li><li>Machine Learning Engineer</li><li>Generative AI Developer</li><li>AI Solutions Architect</li><li>Solutions Engineer</li><li>Integration Engineer</li><li>Platform Engineer</li><li>DevOps Engineer</li><li>Data Engineer</li><li>Technical Lead</li><li>Test Automation Engineer</li><li>Developer Advocate</li><li>Technical Consultant</li></ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Entry requirement kept + programming knowledge; software list -> Claude developer toolchain.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Minimum Entry Requirement</h2>
<p>Knowledge and Skills</p>
<ul>
<li>Able to operate using computer functions</li>
<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>
<li>Working knowledge of Python or TypeScript, REST APIs and the command line</li>
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
<li><a href="https://platform.claude.com/" target="_blank">A Claude Developer Platform account with API credits</a> &ndash; required for the Claude API and Agent SDK labs (pay as you go)</li>
<li><a href="https://claude.ai/" target="_blank">A Claude Pro (or higher) subscription</a> &ndash; required for Claude Code</li>
<li><a href="https://www.python.org/downloads/" target="_blank">Python 3.10 or later</a> &ndash; free</li>
<li><a href="https://nodejs.org/" target="_blank">Node.js (LTS)</a> &ndash; free, for the TypeScript and MCP server labs</li>
<li><a href="https://code.visualstudio.com/" target="_blank">Visual Studio Code</a> &ndash; free</li>
</ul>
<p><strong>Hardware:</strong> Windows PC or Mac laptop</p>
'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Trainer bio: replaces the GCP trainers' blob. data-course-bio so this per-course bio wins over the
-- shared Trainer Profile.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_trainer, 0, @pid, '<p dir="ltr"><strong data-course-bio>Dr. Alfred Ang:</strong> Dr. Alfred Ang builds production applications on Anthropic&#x27;s platform every day, which is exactly the hands-on developer work the Claude Certified Developer - Foundations exam sets out to test. He serves as Managing Director, CIO, CTO and Chief Instructional Designer of Tertiary Infotech Academy Pte Ltd, having founded Tertiary Courses, and he is a full-stack AI developer and Agentic AI solution architect. His recent Claude work includes a WSQ courseware generation platform built with the Claude Agent SDK, an AI-powered CMS whose chatbot and auto-blog scheduler run on the Claude Agent SDK, MCP-connected agent pipelines for course operations, and published Claude Code skill collections for courseware production. His credentials include a PhD in Electrical Engineering from NUS, an MSc in Electrical and Electronic Engineering from NTU, a B.Sc (Hons) in Physics from NUS, Microsoft Certified AI Engineer Associate (AI-102), AWS Certified Solutions Architect and AI Practitioner, and a Certificate in AI Ethics and Governance (Senior Professional) from NTU. He has published more than 20 peer-reviewed papers and co-invented more than 20 US patents.

This exam prep course follows the eight official CCDV-F exam domains, and Dr. Ang sizes each one by its exam weighting. Learners spend the most time on applications and integration, writing code against the Claude API to handle messages, streaming, tool use and errors, and designing Claude applications that are maintainable and configurable. He then covers model selection and optimisation, comparing the Haiku, Sonnet and Opus models on capability, latency and cost and managing tokens and prompt caching, before building agents and workflows with the Claude Agent SDK. Prompt and context engineering, tool implementation and MCP server development follow, and the course closes with security and safety, including guardrails, Claude hooks and API key management, together with Claude Code operation and debugging. Throughout, he frames practice the way the exam does, with scenario questions that reward applied engineering judgement over recall. As an ACTA-certified trainer and DACE-certified curriculum developer, he blends exam-style practice with hands-on coding labs, so learners prepare for the credential while gaining skills they can ship at work the next day. To see the Claude-based systems he builds, visit his GitHub portfolio at https://github.com/alfredang and connect with him on LinkedIn at https://www.linkedin.com/in/angchewhoe/</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Trainer pool: Dr. Alfred Ang (admin_user 25), as on C991 / C437.
INSERT IGNORE INTO mmd_product_trainer (product_id, user_id, sort_order)
SELECT @pid, u.user_id, 0 FROM admin_user u WHERE @ok AND u.user_id = 25 AND u.is_active = 1;

-- Claude Partner Network accreditation card (vocab in MMD_CourseImage_Helper_Data::getAtcPartners)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_atc, 0, @pid, 'claude_partner_network' FROM DUAL WHERE @ok AND @a_atc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------------ cms blocks -----
UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p>', is_active = 1, update_time = NOW()
 WHERE @ok AND identifier = 'course_C1098_funding_and_grant';

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C1098 - Certification Exam', 'course_C1098_certification_exam', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C1098_certification_exam');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE @ok AND identifier = 'course_C1098_certification_exam';

UPDATE cms_block
   SET content = '<p>Once you are prepared, you can register for the <strong>Claude Certified Developer - Foundations (CCDV-F)</strong> exam on the <span style="text-decoration: underline;"><a href="https://anthropic-partners.skilljar.com/claude-certified-developer-foundations-certification" title="Claude Certified Developer - Foundations Certification" target="_blank">Anthropic Partner Academy</a></span>. Registration requires a company email address recognised in the Claude Partner Network. The exam is delivered by Pearson VUE, online proctored or at a test centre, and the certification is valid for 12 months. Note that the course fee does not include the certification exam fee.</p>',
       is_active = 1, update_time = NOW()
 WHERE @ok AND identifier = 'course_C1098_certification_exam';

-- ------------------------------------------------------------- categories -----
SET @a_cname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @c_claude := (SELECT entity_id FROM catalog_category_entity_varchar
                   WHERE attribute_id = @a_cname AND store_id = 0 AND value = 'Claude Certification Exam Prep' LIMIT 1);
SET @c_ai := (SELECT entity_id FROM catalog_category_entity_varchar
               WHERE attribute_id = @a_cname AND store_id = 0 AND value = 'AI Courses' LIMIT 1);
SET @c_parent := (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @c_claude);
SET @c_pos := (SELECT COALESCE(MAX(position), 0) + 1 FROM catalog_category_product
                WHERE category_id = @c_claude AND product_id <> @pid);
SET @ai_pos := (SELECT COALESCE(
                  (SELECT ccp.position FROM catalog_category_product ccp
                     JOIN catalog_product_entity p ON p.entity_id = ccp.product_id
                    WHERE ccp.category_id = @c_ai AND TRIM(p.sku) = 'C437' LIMIT 1),
                  (SELECT COALESCE(MAX(position), 0) + 1 FROM catalog_category_product WHERE category_id = @c_ai)));

DROP TEMPORARY TABLE IF EXISTS tmp_c1098_dropcats;
CREATE TEMPORARY TABLE tmp_c1098_dropcats (category_id INT UNSIGNED PRIMARY KEY);
INSERT IGNORE INTO tmp_c1098_dropcats
SELECT ccp.category_id
  FROM catalog_category_product ccp
  JOIN catalog_category_entity_varchar v
    ON v.entity_id = ccp.category_id AND v.store_id = 0 AND v.attribute_id = @a_cname
 WHERE @ok AND ccp.product_id = @pid
   AND v.value IN ('Cloud Computing', 'Google Cloud', 'Google Certification Exam Prep', 'Google Cloud Certification Prep');

DELETE ccp FROM catalog_category_product ccp JOIN tmp_c1098_dropcats d ON d.category_id = ccp.category_id
 WHERE @ok AND ccp.product_id = @pid;
DELETE cpi FROM catalog_category_product_index cpi JOIN tmp_c1098_dropcats d ON d.category_id = cpi.category_id
 WHERE @ok AND cpi.product_id = @pid;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @c_claude, @pid, @c_pos FROM DUAL WHERE @ok AND @c_claude IS NOT NULL;
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @c_ai, @pid, @ai_pos FROM DUAL WHERE @ok AND @c_ai IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_claude, @pid, @c_pos, 1, 1, 4 FROM DUAL WHERE @ok AND @c_claude IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_ai, @pid, @ai_pos, 1, 1, 4 FROM DUAL WHERE @ok AND @c_ai IS NOT NULL;
-- the anchor parent ("Certification Exam Prep") lists it through the child (C1098 is also a direct member)
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_parent, @pid, @c_pos, 0, 1, 4 FROM DUAL WHERE @ok AND @c_claude IS NOT NULL AND @c_parent > 2;

-- ---------------------------------------------------------------- upsells -----
DELETE FROM catalog_product_link WHERE @ok AND product_id = @pid AND link_type_id IN (1, 4);

INSERT IGNORE INTO catalog_product_link (product_id, linked_product_id, link_type_id)
SELECT @pid, p.entity_id, 4
  FROM catalog_product_entity p
 WHERE @ok AND TRIM(p.sku) IN ('C437', 'C991', 'TGS-2026061312', 'TGS-2025052468', 'C1382', 'C197');

INSERT IGNORE INTO catalog_product_link_attribute_int (product_link_attribute_id, link_id, value)
SELECT a.product_link_attribute_id, l.link_id,
       FIELD(TRIM(p.sku), 'C437', 'C991', 'TGS-2026061312', 'TGS-2025052468', 'C1382', 'C197')
  FROM catalog_product_link l
  JOIN catalog_product_entity p ON p.entity_id = l.linked_product_id
  JOIN catalog_product_link_attribute a
    ON a.link_type_id = l.link_type_id AND a.product_link_attribute_code = 'position'
 WHERE @ok AND l.product_id = @pid AND l.link_type_id = 4;

-- ------------------------------------------------------------ 301 rewrites -----
-- 1) Remember the product's old system paths (bare + category-prefixed, with or without -NNNN suffix).
DROP TEMPORARY TABLE IF EXISTS tmp_c1098_old;
CREATE TEMPORARY TABLE tmp_c1098_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c1098_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND request_path LIKE CONCAT('%', @old_slug, '%.html');

-- 2) Paths under the dropped categories go away; rename the rest in place (prefix kept, suffix dropped)
--    so the new slug resolves without a rewrite refresh.
DELETE r FROM core_url_rewrite r JOIN tmp_c1098_dropcats d ON d.category_id = r.category_id
 WHERE @ok AND r.product_id = @pid AND r.is_system = 1;

UPDATE core_url_rewrite
   SET request_path = CONCAT(LEFT(request_path, LENGTH(request_path) - LENGTH(SUBSTRING_INDEX(request_path, '/', -1))),
                             @new_slug, '.html')
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND request_path LIKE CONCAT('%', @old_slug, '%.html');

-- 3) Legacy aliases that pointed at any old path, plus product 740's rows squatting the old ACE slug
--    (sent to the ML Engineer course) -> the Google ACE WSQ twin (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@twin_slug, '.html'), product_id = NULL
 WHERE @ok AND store_id = 1 AND is_system = 0 AND options = 'RP'
   AND (target_path LIKE CONCAT('%', @old_slug, '%') OR request_path LIKE CONCAT('%', @old_slug, '%'));

-- 4) Every old path of C1098 -> the Google ACE WSQ twin.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@twin_slug, '.html'), 0, 'RP'
  FROM tmp_c1098_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c1098_old;
DROP TEMPORARY TABLE IF EXISTS tmp_c1098_dropcats;

-- 5) The old CCDV-F slug (C439's previous life) -> this course. Fresh id_path, detached from C439.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html'), product_id = NULL, category_id = NULL,
       id_path = CONCAT('manual-301-', MD5(request_path), '-', store_id)
 WHERE @ok AND store_id = 1 AND is_system = 0 AND options = 'RP'
   AND (request_path = CONCAT(@ccdvf_old, '.html') OR request_path LIKE CONCAT('%/', @ccdvf_old, '.html'));

-- -------------------------------------------------------- search redirects -----
UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, @new_slug, '.html')
 WHERE @ok AND store_id = 1 AND query_text IN ('C1098', 'c01098');

UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, 'generative-ai-for-content-creation.html')
 WHERE @ok AND store_id = 1 AND query_text IN ('C439', 'c0439')
   AND redirect = CONCAT(@base, @ccdvf_old, '.html');

UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, @twin_slug, '.html')
 WHERE @ok AND store_id = 1 AND redirect LIKE CONCAT('%', @old_slug, '%')
   AND query_text LIKE '%cloud engineer%';

UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, 'google-certification-courses.html')
 WHERE @ok AND store_id = 1 AND redirect LIKE CONCAT('%', @old_slug, '%')
   AND query_text IN ('google certification', 'goolge certification');

-- anything else that still points at the old course (quantum / vertex leftovers): let search answer
UPDATE catalogsearch_query
   SET redirect = NULL
 WHERE @ok AND store_id = 1 AND redirect LIKE CONCAT('%', @old_slug, '%');

UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, @new_slug, '.html')
 WHERE @ok AND store_id = 1 AND (redirect IS NULL OR redirect = '')
   AND query_text IN ('CCDV-F', 'ccdvf', 'ccdv', 'claude certified developer',
                      'Claude Certified Developer - Foundations', 'claude developer certification');

INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed)
SELECT t.q, 1, 1, CONCAT(@base, @new_slug, '.html'), 1, 0, 1, 0
  FROM (SELECT 'CCDV-F' AS q UNION ALL SELECT 'claude certified developer') t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM catalogsearch_query s WHERE s.store_id = 1 AND s.query_text = t.q);
