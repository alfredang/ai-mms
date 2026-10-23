-- C740: "Google Professional Machine Learning Engineer Training"
--    -> "Claude Certified Architect - Professional (CCAR-P) Exam Prep".
--
-- Content follows the official CCAR-P Exam Guide (63 items, 120 min, scaled 720 / 1,000, $175 USD,
-- valid 12 months; blueprint as summarised at tutorialsdojo.com/ccar-p-claude-certified-architect-
-- professional-study-guide): the 7 topics ARE the 7 exam domains, in exam-guide order
-- (17 / 13 / 19 / 16 / 14 / 14 / 7 %). Sibling of C991 CCAO-F (1833) / C437 CCAR-F (1834) /
-- C1098 CCDV-F (1836); Why Take tiles as in 1837-1839.
--
-- 1. name, url_key/url_path (google-professional-machine-learning-engineer-training ->
--    claude-certified-architect-professional-ccar-p-exam-prep), cover alt + gallery labels, metas
--    (meta_title stored BARE), level -> Advanced, new cover PNG on R2 (the PNG bakes the title).
-- 2. About / topics / Job Roles / keywords / prerequisite rewritten. Dr. Alfred Ang is the SOLE trainer:
--    CCAR-P bio (data-course-bio), mmd_product_trainer = user 25 only, legacy `trainers` multiselect = his
--    option only (was Eve Tan / Truman Ng / Alfred).
-- 3. atc_partners = claude_partner_network -> "Claude Partner Network" card. Certification-exam block:
--    Google/Kryterion copy -> Anthropic Partner Academy registration (+ register with our partner network).
-- 4. "Why Take This Course?" gets two tiles at the front (course_C740_why_take): Free Practice Exam
--    (exams.tertiaryinfotech.com CCAR-P) + Register with Our Claude Partner Network. The Bonus practice
--    exam card links to the CCAR-P exam (course_C740_practice_exams).
-- 5. Categories: out of Cloud Computing / Google Cloud / Computer Vision / Google Looker Studio / Google
--    Certification Exam Prep / Google Cloud Certification Prep (+ their anchor-inherited index rows);
--    into Claude Certification Exam Prep (alphabetical: after C437 Architect - Foundations, so C991 /
--    C1098 shift down one) and AI Courses (beside C437). All Courses / Infocomm / Cert Exam Prep kept.
-- 6. Upsells: -> the Claude family.
-- 7. 301s: system rows renamed in place to the new slug. Every OLD path of C740 and its legacy aliases
--    301 one hop to the live WSQ twin TGS-2023040476 (wsq-google-professional-machine-learning-engineer-
--    training), which teaches what those URLs promised. Old-slug matches use an exact path-segment REGEXP:
--    a plain LIKE '%old-slug%' would also hit the twin's own "wsq-google-..." rows and product 1677's
--    "...-training-practice-exams" rows. The old CCAR-P slug (C364's past life, 301ing to Generative AI
--    for Script Development) is repointed here -- same exam.
-- 8. Search: c740 + CCAR-P queries -> new slug; Google ML queries -> WSQ twin.
-- Fee / duration / sessions / funding block unchanged. Schedule template unchanged (no WSQ CCAR-P twin).
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent. Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C740' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @old_title := 'Google Professional Machine Learning Engineer Training';
SET @new_title := 'Claude Certified Architect - Professional (CCAR-P) Exam Prep';
SET @old_slug  := 'google-professional-machine-learning-engineer-training';
SET @old_re    := '(^|/)google-professional-machine-learning-engineer-training(-[0-9]+)?[.]html$';
SET @new_slug  := 'claude-certified-architect-professional-ccar-p-exam-prep';
SET @twin_slug := 'wsq-google-professional-machine-learning-engineer-training';
SET @ccarp_old := 'claude-certified-architect-professional-certification';
SET @base      := 'https://www.tertiarycourses.com.sg/';
SET @pe        := 'https://exams.tertiaryinfotech.com/practice-exams/anthropic/anthropic-ccar-professional';

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
SET @a_tr      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainers');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_atc     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'atc_partners');
SET @a_level   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'level');
SET @o_adv     := (SELECT o.option_id FROM eav_attribute_option o
                     JOIN eav_attribute_option_value ov ON ov.option_id = o.option_id AND ov.store_id = 0
                    WHERE o.attribute_id = @a_level AND ov.value = 'Advanced' LIMIT 1);
SET @o_ang     := (SELECT o.option_id FROM eav_attribute_option o
                     JOIN eav_attribute_option_value ov ON ov.option_id = o.option_id AND ov.store_id = 0
                    WHERE o.attribute_id = @a_tr AND ov.value = 'Dr. Alfred Ang' LIMIT 1);

-- ------------------------------------------------------------ name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey AND store_id = 0;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath AND store_id = 0;

-- store 1 url_path still held the old slug
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
       'Prepare for the Claude Certified Architect - Professional (CCAR-P) exam. Cover all 7 exam domains, from solution architecture and context engineering to RAG, MCP, evaluation and AI governance.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C740-20261023-170457.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_level, 0, @pid, @o_adv FROM DUAL WHERE @ok AND @o_adv IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ text content -----
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND store_id <> 0
   AND attribute_id IN (@a_short, @a_desc, @a_who, @a_mkey, @a_trainer, @a_tr, @a_prereq, @a_atc);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid,
       'Claude Certified Architect Professional, CCAR-P, Claude Certified Architect, Claude Certification, Anthropic Certification, Claude Exam Prep, Claude Partner Network, AI Solution Architecture, Context Engineering, RAG, MCP, Claude Code, AI Governance'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- What's This Course About
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Claude Certified Architect - Professional (CCAR-P) Exam Prep prepares you for the Claude Certified Architect - Professional exam from Anthropic, the advanced architect credential in the Claude certification programme. It validates that you can turn business problems into scalable, production-grade Claude solutions, choosing the right models, architectural patterns and API approaches, and building evaluation, security, compliance and governance into the design. The certification is intended for experienced solution architects, AI engineers and technical leads who design and deliver Claude-powered systems for real organisations.</p><p>The course follows the seven official exam domains and gives each one the time its exam weighting deserves. You will start with solution design and architecture, translating business requirements into end-to-end designs and choosing between workflow-based, agentic, augmented LLM and multi-agent patterns. You will then cover Claude models, prompting and context engineering, including model trade-offs, system prompts, guardrails, prompt caching and Skills, followed by integration, the most heavily weighted domain, covering RAG pipelines, MCP, APIs, agent-to-agent communication, least-privilege tool access and observability.</p><p>The course continues with evaluation, testing and optimisation, governance, safety and risk management, including human-in-the-loop controls and regulatory obligations such as GDPR and HIPAA, and stakeholder communication and lifecycle management, and closes with developer productivity and operational enablement with Claude Code. Each domain combines explanation, architecture case studies, hands-on labs and exam-style scenario questions. The CCAR-P exam has 63 multiple-choice and multiple-response questions in 120 minutes, delivered by Pearson VUE online or at a test centre, with a passing scaled score of 720 out of 1,000. As a member of the Claude Partner Network, Tertiary Infotech Academy aligns this course with Anthropic&#x27;s official exam guide. By the end, you will be able to architect production Claude solutions with confidence and be well prepared to pass the exam.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Course outline: the 7 exam domains (LSN_DATA marker = the admin topic editor's source)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title": "Topic 1: Solution Design and Architecture", "subsecs": []}, {"title": "Topic 2: Claude Models, Prompting, and Context Engineering", "subsecs": []}, {"title": "Topic 3: Integration", "subsecs": []}, {"title": "Topic 4: Evaluation, Testing, and Optimisation", "subsecs": []}, {"title": "Topic 5: Governance, Safety, and Risk Management", "subsecs": []}, {"title": "Topic 6: Stakeholder Communication and Lifecycle Management", "subsecs": []}, {"title": "Topic 7: Developer Productivity and Operational Enablement", "subsecs": []}] -->
<p><strong>Topic 1: Solution Design and Architecture</strong></p>
<p><strong>Topic 2: Claude Models, Prompting, and Context Engineering</strong></p>
<p><strong>Topic 3: Integration</strong></p>
<p><strong>Topic 4: Evaluation, Testing, and Optimisation</strong></p>
<p><strong>Topic 5: Governance, Safety, and Risk Management</strong></p>
<p><strong>Topic 6: Stakeholder Communication and Lifecycle Management</strong></p>
<p><strong>Topic 7: Developer Productivity and Operational Enablement</strong></p>
'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Job Roles
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul><li>AI Solutions Architect</li><li>Solutions Architect</li><li>Enterprise Architect</li><li>Technical Architect</li><li>Cloud Architect</li><li>AI Engineer</li><li>Senior Software Engineer</li><li>Machine Learning Engineer</li><li>Generative AI Lead</li><li>Forward Deployed Engineer</li><li>Solutions Engineer</li><li>Platform Engineer</li><li>Technical Lead</li><li>Engineering Manager</li><li>AI Consultant</li><li>AI Product Manager</li><li>AI Governance Lead</li><li>Head of AI</li></ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Entry requirement kept + architect-level experience; software list GCP -> Claude toolchain.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Minimum Entry Requirement</h2>
<p>Knowledge and Skills</p>
<ul>
<li>Able to operate using computer functions</li>
<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>
<li>Experience designing or building LLM-powered applications, with working knowledge of Python or TypeScript and REST APIs</li>
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
<li><a href="https://platform.claude.com/" target="_blank">A Claude Developer Platform account with API credits</a> &ndash; required for the Claude API, RAG and MCP labs (pay as you go)</li>
<li><a href="https://claude.ai/" target="_blank">A Claude Pro (or higher) subscription</a> &ndash; required for Claude Code</li>
<li><a href="https://www.python.org/downloads/" target="_blank">Python 3.10 or later</a> &ndash; free</li>
<li><a href="https://nodejs.org/" target="_blank">Node.js (LTS)</a> &ndash; free, for the MCP server labs</li>
<li><a href="https://code.visualstudio.com/" target="_blank">Visual Studio Code</a> &ndash; free</li>
</ul>
<p><strong>Hardware:</strong> Windows PC or Mac laptop</p>
'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Trainer bio: Dr. Alfred Ang only (replaces the Truman Ng / Eve Tan / GCP blob). data-course-bio so
-- this per-course bio wins over the shared Trainer Profile.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_trainer, 0, @pid, '<p dir="ltr"><strong data-course-bio>Dr. Alfred Ang:</strong> Dr. Alfred Ang designs and runs production systems on Anthropic&#x27;s platform every day, which is exactly the architect-level work the Claude Certified Architect - Professional exam sets out to test. He serves as Managing Director, CIO, CTO and Chief Instructional Designer of Tertiary Infotech Academy Pte Ltd, having founded Tertiary Courses, and he is a full-stack AI developer and Agentic AI solution architect. His recent Claude work includes a WSQ courseware generation platform built with the Claude Agent SDK, an AI-powered CMS whose chatbot and auto-blog scheduler run on the Claude Agent SDK, MCP-connected multi-agent pipelines for course operations, and Claude Code skill collections and team configurations for courseware production. His credentials include a PhD in Electrical Engineering from NUS, an MSc in Electrical and Electronic Engineering from NTU, a B.Sc (Hons) in Physics from NUS, Microsoft Certified AI Engineer Associate (AI-102), AWS Certified Solutions Architect and AI Practitioner, and a Certificate in AI Ethics and Governance (Senior Professional) from NTU. He has published more than 20 peer-reviewed papers and co-invented more than 20 US patents.

This exam prep course follows the seven official CCAR-P exam domains, and Dr. Ang sizes each one by its exam weighting. Learners spend the most time on integration and solution design, designing RAG pipelines, choosing between MCP, APIs and agent-to-agent communication, applying least-privilege tool access, and deciding when a fixed workflow beats an autonomous agent or a multi-agent system. He then covers model selection, prompt and context engineering with prompt caching and Skills, evaluation and optimisation, and governance, safety and compliance, including human-in-the-loop controls. The course closes with stakeholder discovery, architecture documentation and lifecycle management, and with rolling out Claude Code across engineering teams. Throughout, he frames practice the way the exam does, with scenario questions that reward architectural judgement over recall, drawn from the trade-offs he makes in his own Claude deployments. As an ACTA-certified trainer and DACE-certified curriculum developer, he blends exam-style practice with hands-on architecture labs, so learners prepare for the credential while gaining skills they can apply at work the next day. To see the Claude-based systems he builds, visit his GitHub portfolio at https://github.com/alfredang and connect with him on LinkedIn at https://www.linkedin.com/in/angchewhoe/</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Sole trainer: Dr. Alfred Ang (admin_user 25) in the trainer pool and the legacy multiselect.
DELETE FROM mmd_product_trainer WHERE @ok AND product_id = @pid AND user_id <> 25;
INSERT IGNORE INTO mmd_product_trainer (product_id, user_id, sort_order)
SELECT @pid, u.user_id, 0 FROM admin_user u WHERE @ok AND u.user_id = 25 AND u.is_active = 1;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_tr, 0, @pid, @o_ang FROM DUAL WHERE @ok AND @o_ang IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Claude Partner Network accreditation card (vocab in MMD_CourseImage_Helper_Data::getAtcPartners)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_atc, 0, @pid, 'claude_partner_network' FROM DUAL WHERE @ok AND @a_atc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------------ cms blocks -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT t.title, t.identifier, '', NOW(), NOW(), 1
  FROM (SELECT 'Course C740 - Certification Exam' AS title, 'course_C740_certification_exam' AS identifier
        UNION ALL SELECT 'Course C740 - Why Take This Course', 'course_C740_why_take'
        UNION ALL SELECT 'Course C740 - Practice Exams', 'course_C740_practice_exams') t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block b WHERE b.identifier = t.identifier);

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier IN ('course_C740_certification_exam', 'course_C740_why_take', 'course_C740_practice_exams');

UPDATE cms_block
   SET content = '<p>Once you are prepared, you can register for the <strong>Claude Certified Architect - Professional (CCAR-P)</strong> exam on the <span style="text-decoration: underline;"><a href="https://anthropic-partners.skilljar.com/claude-certified-architect-professional-certification" title="Claude Certified Architect - Professional Certification" target="_blank">Anthropic Partner Academy</a></span>. Claude certification exams are open to people who work at organisations in the Claude Partner Network, and registration requires a company email address on the organisation&rsquo;s partner record; if your organisation is not a member, you can register with our Claude Partner Network. The exam is delivered by Pearson VUE, online proctored or at a test centre, and the certification is valid for 12 months. Note that the course fee does not include the certification exam fee.</p>',
       is_active = 1, update_time = NOW()
 WHERE @ok AND identifier = 'course_C740_certification_exam';

UPDATE cms_block
   SET content = CONCAT(
'<li class="why-tile why-tile--practice"><span class="why-tile__icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span>',
'<strong class="why-tile__title">Free Practice Exam</strong>',
'<span class="why-tile__text">Test yourself on realistic scenario questions across all 7 CCAR-P exam domains before you book the real exam. <a href="', @pe, '" target="_blank" rel="noopener">Start the free practice exam &rarr;</a></span></li>',
'<li class="why-tile why-tile--partner"><span class="why-tile__icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/></svg></span>',
'<strong class="why-tile__title">Register with Our Claude Partner Network</strong>',
'<span class="why-tile__text">Official Claude exams are open only through the Claude Partner Network. Register with our partner network to access the Anthropic Partner Academy and book your CCAR-P exam.</span></li>'),
       is_active = 1, update_time = NOW()
 WHERE @ok AND identifier = 'course_C740_why_take';

UPDATE cms_block
   SET content = CONCAT(
'<p>Get exam-ready on our free <strong>CCAR-P Practice Exam</strong> &mdash; realistic scenario questions across all 7 official exam domains, in <strong>Practice Mode</strong> and timed <strong>Exam Mode</strong>, which you can retake as many times as you like before the real exam.</p>',
'<p><a class="practice-exam-cta" href="', @pe, '" target="_blank" rel="noopener">Start Practising &rarr;</a></p>'),
       is_active = 1, update_time = NOW()
 WHERE @ok AND identifier = 'course_C740_practice_exams';

-- ------------------------------------------------------------- categories -----
SET @a_cname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @c_claude := (SELECT entity_id FROM catalog_category_entity_varchar
                   WHERE attribute_id = @a_cname AND store_id = 0 AND value = 'Claude Certification Exam Prep' LIMIT 1);
SET @c_ai := (SELECT entity_id FROM catalog_category_entity_varchar
               WHERE attribute_id = @a_cname AND store_id = 0 AND value = 'AI Courses' LIMIT 1);
SET @c_parent := (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @c_claude);
SET @ai_pos := (SELECT COALESCE(
                  (SELECT ccp.position FROM catalog_category_product ccp
                     JOIN catalog_product_entity p ON p.entity_id = ccp.product_id
                    WHERE ccp.category_id = @c_ai AND TRIM(p.sku) = 'C437' LIMIT 1),
                  (SELECT COALESCE(MAX(position), 0) + 1 FROM catalog_category_product WHERE category_id = @c_ai)));

DROP TEMPORARY TABLE IF EXISTS tmp_c740_dropcats;
CREATE TEMPORARY TABLE tmp_c740_dropcats (category_id INT UNSIGNED PRIMARY KEY);
INSERT IGNORE INTO tmp_c740_dropcats
SELECT ccp.category_id
  FROM catalog_category_product ccp
  JOIN catalog_category_entity_varchar v
    ON v.entity_id = ccp.category_id AND v.store_id = 0 AND v.attribute_id = @a_cname
 WHERE @ok AND ccp.product_id = @pid
   AND v.value IN ('Cloud Computing', 'Google Cloud', 'Computer Vision', 'Google Looker Studio',
                   'Google Certification Exam Prep', 'Google Cloud Certification Prep');

DELETE ccp FROM catalog_category_product ccp JOIN tmp_c740_dropcats d ON d.category_id = ccp.category_id
 WHERE @ok AND ccp.product_id = @pid;
DELETE cpi FROM catalog_category_product_index cpi JOIN tmp_c740_dropcats d ON d.category_id = cpi.category_id
 WHERE @ok AND cpi.product_id = @pid;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @c_claude, @pid, 3 FROM DUAL WHERE @ok AND @c_claude IS NOT NULL;
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @c_ai, @pid, @ai_pos FROM DUAL WHERE @ok AND @c_ai IS NOT NULL;

-- Claude Certification Exam Prep order: funded first, then C- alphabetical by name
-- (Architect - Foundations, Architect - Professional, Associate, Developer).
UPDATE catalog_category_product ccp
  JOIN catalog_product_entity p ON p.entity_id = ccp.product_id
   SET ccp.position = FIELD(TRIM(p.sku), 'TGS-2026061312', 'C437', 'C740', 'C991', 'C1098')
 WHERE @ok AND ccp.category_id = @c_claude AND TRIM(p.sku) IN ('TGS-2026061312', 'C437', 'C740', 'C991', 'C1098');
UPDATE catalog_category_product_index cpi
  JOIN catalog_product_entity p ON p.entity_id = cpi.product_id
   SET cpi.position = FIELD(TRIM(p.sku), 'TGS-2026061312', 'C437', 'C740', 'C991', 'C1098')
 WHERE @ok AND cpi.category_id = @c_claude AND TRIM(p.sku) IN ('TGS-2026061312', 'C437', 'C991', 'C1098');

INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_claude, @pid, 3, 1, 1, 4 FROM DUAL WHERE @ok AND @c_claude IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_ai, @pid, @ai_pos, 1, 1, 4 FROM DUAL WHERE @ok AND @c_ai IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @c_parent, @pid, 3, 0, 1, 4 FROM DUAL WHERE @ok AND @c_claude IS NOT NULL AND @c_parent > 2;

-- Anchor-inherited rows left over from the dropped categories (Software Training / Google via Looker
-- Studio, AI Applications Series via Computer Vision): drop every is_parent=0 row whose category is no
-- longer an ancestor of one of C740's direct categories.
DELETE cpi FROM catalog_category_product_index cpi
 WHERE @ok AND cpi.product_id = @pid AND cpi.is_parent = 0
   AND NOT EXISTS (SELECT 1 FROM catalog_category_product ccp
                     JOIN catalog_category_entity ce ON ce.entity_id = ccp.category_id
                    WHERE ccp.product_id = @pid
                      AND CONCAT('/', ce.path, '/') LIKE CONCAT('%/', cpi.category_id, '/%'));

-- ---------------------------------------------------------------- upsells -----
DELETE FROM catalog_product_link WHERE @ok AND product_id = @pid AND link_type_id IN (1, 4);

INSERT IGNORE INTO catalog_product_link (product_id, linked_product_id, link_type_id)
SELECT @pid, p.entity_id, 4
  FROM catalog_product_entity p
 WHERE @ok AND TRIM(p.sku) IN ('C437', 'C1098', 'C991', 'TGS-2026061312', 'TGS-2025052468', 'C1382');

INSERT IGNORE INTO catalog_product_link_attribute_int (product_link_attribute_id, link_id, value)
SELECT a.product_link_attribute_id, l.link_id,
       FIELD(TRIM(p.sku), 'C437', 'C1098', 'C991', 'TGS-2026061312', 'TGS-2025052468', 'C1382')
  FROM catalog_product_link l
  JOIN catalog_product_entity p ON p.entity_id = l.linked_product_id
  JOIN catalog_product_link_attribute a
    ON a.link_type_id = l.link_type_id AND a.product_link_attribute_code = 'position'
 WHERE @ok AND l.product_id = @pid AND l.link_type_id = 4;

-- ------------------------------------------------------------ 301 rewrites -----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c740_old;
CREATE TEMPORARY TABLE tmp_c740_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c740_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1 AND request_path REGEXP @old_re;

-- 2) Paths under the dropped categories go away; rename the rest in place (prefix kept) so the new
--    slug resolves without a rewrite refresh.
DELETE r FROM core_url_rewrite r JOIN tmp_c740_dropcats d ON d.category_id = r.category_id
 WHERE @ok AND r.product_id = @pid AND r.is_system = 1;

UPDATE core_url_rewrite
   SET request_path = CONCAT(LEFT(request_path, LENGTH(request_path) - LENGTH(SUBSTRING_INDEX(request_path, '/', -1))),
                             @new_slug, '.html')
 WHERE @ok AND product_id = @pid AND is_system = 1 AND request_path REGEXP @old_re;

-- 3) Legacy aliases that pointed at the old course -> the Google ML WSQ twin (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@twin_slug, '.html'), product_id = NULL
 WHERE @ok AND store_id = 1 AND is_system = 0 AND options = 'RP'
   AND (product_id = @pid OR target_path REGEXP @old_re);

-- 4) Every old path of C740 -> the Google ML WSQ twin.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@twin_slug, '.html'), 0, 'RP'
  FROM tmp_c740_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c740_old;
DROP TEMPORARY TABLE IF EXISTS tmp_c740_dropcats;

-- 5) The old CCAR-P slug (C364's previous life) -> this course. Fresh id_path, detached from C364.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html'), product_id = NULL, category_id = NULL,
       id_path = CONCAT('manual-301-', MD5(request_path), '-', store_id)
 WHERE @ok AND store_id = 1 AND is_system = 0 AND options = 'RP'
   AND (request_path = CONCAT(@ccarp_old, '.html') OR request_path LIKE CONCAT('%/', @ccarp_old, '.html'));

-- -------------------------------------------------------- search redirects -----
UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, @new_slug, '.html')
 WHERE @ok AND store_id = 1 AND query_text IN ('C740', 'c0740');

UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, @twin_slug, '.html')
 WHERE @ok AND store_id = 1 AND redirect REGEXP @old_re AND query_text LIKE '%machine learning%';

-- anything else that still points at the old course: let search answer
UPDATE catalogsearch_query
   SET redirect = NULL
 WHERE @ok AND store_id = 1 AND redirect REGEXP @old_re;

UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, @new_slug, '.html')
 WHERE @ok AND store_id = 1
   AND (redirect IS NULL OR redirect = '' OR redirect = CONCAT(@base, @ccarp_old, '.html'))
   AND query_text IN ('CCAR-P', 'ccarp', 'ccar p', 'claude certified architect professional',
                      'Claude Certified Architect - Professional', 'claude architect professional');

INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed)
SELECT t.q, 1, 1, CONCAT(@base, @new_slug, '.html'), 1, 0, 1, 0
  FROM (SELECT 'CCAR-P' AS q UNION ALL SELECT 'claude certified architect professional') t
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM catalogsearch_query s WHERE s.store_id = 1 AND s.query_text = t.q);
