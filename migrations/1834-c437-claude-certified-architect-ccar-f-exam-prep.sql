-- C437: "Claude Certified Architect - Foundations Certification"
--    -> "Claude Certified Architect - Foundations (CCAR-F) Exam Prep".  Same course, same exam.
--
-- Content follows the official CCAR-F Exam Guide v1.0 (effective July 2026, linked from
-- anthropic-partners.skilljar.com/claude-certified-architect-foundations-certification): the 5 topics
-- ARE the 5 exam domains, in exam-guide order (27 / 18 / 20 / 20 / 15 %).
--
-- 1. name, url_key/url_path (claude-certified-architect-foundations-certification ->
--    claude-certified-architect-foundations-ccar-f-exam-prep), cover alt + gallery labels (the gallery
--    label still said "Virtual Reality ... Unreal Engine"), metas (meta_title stored BARE), new cover
--    PNG on R2 (the PNG bakes the title).
-- 2. About / topics / Job Roles (were still the Unreal Engine game-dev roles) / keywords rewritten.
-- 3. Trainer blob trimmed to Dr. Alfred Ang, the only trainer in mmd_product_trainer (the other two
--    bios were AutoCAD / game-dev copy).
-- 4. atc_partners = claude_partner_network -> "Claude Partner Network" card on the page.
--    New course_C437_certification_exam block (exam registration on the Anthropic Partner Academy).
-- 5. 301s: system rows renamed in place to the new slug; every old path + legacy alias 301s one hop
--    to the new bare slug.
-- 6. Search: c437/c0437 -> new slug. Title queries that point at the WSQ twin are left alone.
-- Fee / duration / sessions / categories / funding block / schedule template unchanged.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent. Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C437' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @old_title := 'Claude Certified Architect - Foundations Certification';
SET @new_title := 'Claude Certified Architect - Foundations (CCAR-F) Exam Prep';
SET @old_slug  := 'claude-certified-architect-foundations-certification';
SET @new_slug  := 'claude-certified-architect-foundations-ccar-f-exam-prep';
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
SET @a_atc     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'atc_partners');

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

-- gallery label still held a two-lives-ago title (with a stray non-UTF-8 byte) -> set outright
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid;

-- ------------------------------------------------------- meta + cover -----
-- meta_title stored BARE (MMD_Seotitle appends the brand at render time).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description is varchar(255).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid,
       'Prepare for the Claude Certified Architect - Foundations (CCAR-F) exam. Cover all 5 exam domains: agentic architecture, MCP tool design, Claude Code workflows, structured output and context reliability.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C437-20261023-163503.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- ------------------------------------------------------ text content -----
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND store_id <> 0
   AND attribute_id IN (@a_short, @a_desc, @a_who, @a_mkey, @a_trainer, @a_atc);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid,
       'Claude Certified Architect, CCAR-F, Claude Certified Architect Foundations, Claude Certification, Anthropic Certification, Claude Exam Prep, Claude Partner Network, Claude Code, Claude Agent SDK, Claude API, MCP, Model Context Protocol, AI Certification'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- What's This Course About
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Claude Certified Architect - Foundations (CCAR-F) Exam Prep prepares you for the Claude Certified Architect - Foundations exam from Anthropic, which validates that you can make informed decisions about tradeoffs when implementing real-world solutions with Claude. The exam tests foundational knowledge across Claude Code, the Claude Agent SDK, the Claude API and Model Context Protocol (MCP), the core technologies used to build production-grade applications with Claude. It is aimed at solution architects, AI engineers and senior developers who design and build production applications, agents and workflows with Claude.</p><p>The course follows the five official exam domains and their weightings. You will start with agentic architecture and orchestration (27%), covering agentic loops, coordinator-subagent patterns, subagent context passing, workflow enforcement and handoff, Agent SDK hooks, task decomposition and session state. Next you will study tool design and MCP integration (18%), including clear tool interfaces, structured error responses, distributing tools across agents, integrating MCP servers and choosing the right built-in tools. You will then cover Claude Code configuration and workflows (20%), such as the CLAUDE.md hierarchy, custom slash commands and skills, path-specific rules, plan mode versus direct execution, iterative refinement and CI/CD integration.</p><p>The course continues with prompt engineering and structured output (20%), including explicit criteria, few-shot prompting, structured output with tool use and JSON schemas, validation and retry loops, batch processing and multi-pass review, and closes with context management and reliability (15%), covering context preservation, escalation and ambiguity resolution, error propagation across multi-agent systems, large codebase exploration, human review and confidence calibration, and information provenance. Each domain combines explanation, hands-on practice with Claude Code and the Agent SDK, and scenario-based questions modelled on the exam&rsquo;s customer use cases, such as customer support agents, multi-agent research pipelines and Claude Code in CI/CD.</p><p>The CCAR-F exam has 60 multiple-choice and multiple-response questions in 120 minutes, built around 4 scenarios drawn from a bank of 6, and is delivered by Pearson VUE online or at a test centre, with a passing scaled score of 720 out of 1,000. By the end, you will be able to design robust Claude-based systems with confidence and be well prepared to pass the exam.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Course outline: the 5 exam domains (LSN_DATA marker = the admin topic editor's source)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title": "Topic 1: Agentic Architecture and Orchestration", "subsecs": []}, {"title": "Topic 2: Tool Design and MCP Integration", "subsecs": []}, {"title": "Topic 3: Claude Code Configuration and Workflows", "subsecs": []}, {"title": "Topic 4: Prompt Engineering and Structured Output", "subsecs": []}, {"title": "Topic 5: Context Management and Reliability", "subsecs": []}] -->
<p><strong>Topic 1: Agentic Architecture and Orchestration</strong></p>
<p><strong>Topic 2: Tool Design and MCP Integration</strong></p>
<p><strong>Topic 3: Claude Code Configuration and Workflows</strong></p>
<p><strong>Topic 4: Prompt Engineering and Structured Output</strong></p>
<p><strong>Topic 5: Context Management and Reliability</strong></p>
'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Job Roles (were still the Unreal Engine game-dev list)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul><li>Solution Architect</li><li>AI Solutions Architect</li><li>Cloud Solutions Architect</li><li>Enterprise Architect</li><li>AI Engineer</li><li>Machine Learning Engineer</li><li>Software Engineer</li><li>Senior Software Developer</li><li>Full-Stack Developer</li><li>Backend Developer</li><li>DevOps Engineer</li><li>Platform Engineer</li><li>Solutions Engineer</li><li>Forward Deployed Engineer</li><li>Technical Lead</li><li>Engineering Manager</li><li>AI Technical Consultant</li><li>AI Product Manager</li></ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Trainer blob: keep Dr. Alfred Ang's paragraph only (the only trainer in mmd_product_trainer).
UPDATE catalog_product_entity_text
   SET value = REPLACE(LEFT(value, LOCATE('</p>', value) + 3),
                       'This certification course follows the official CCAR-F exam domains',
                       'This exam prep course follows the five official CCAR-F exam domains')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_trainer AND store_id = 0
   AND LOCATE('<p dir="ltr"><strong data-course-bio>Dr. Alfred Ang:</strong>', value) = 1
   AND LOCATE('data-course-bio>Jyoti Chopra:', value) > 0;

-- Claude Partner Network accreditation card (vocab in MMD_CourseImage_Helper_Data::getAtcPartners)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_atc, 0, @pid, 'claude_partner_network' FROM DUAL WHERE @ok AND @a_atc IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------------ cms blocks -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C437 - Certification Exam', 'course_C437_certification_exam', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C437_certification_exam');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE @ok AND identifier = 'course_C437_certification_exam';

UPDATE cms_block
   SET content = '<p>Once you are prepared, you can register for the <strong>Claude Certified Architect - Foundations (CCAR-F)</strong> exam on the <span style="text-decoration: underline;"><a href="https://anthropic-partners.skilljar.com/claude-certified-architect-foundations-certification" title="Claude Certified Architect - Foundations Certification" target="_blank">Anthropic Partner Academy</a></span>. Claude certification exams are open to people who work at organisations in the Claude Partner Network, and registration requires a company email address on the organisation&rsquo;s partner record. The exam is delivered by Pearson VUE, online proctored or at a test centre, and the certification is valid for 12 months. Note that the course fee does not include the certification exam fee.</p>',
       is_active = 1, update_time = NOW()
 WHERE @ok AND identifier = 'course_C437_certification_exam';

-- ------------------------------------------------------------ 301 rewrites -----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c437_old;
CREATE TEMPORARY TABLE tmp_c437_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c437_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename the system rows in place so the new slug resolves without a rewrite refresh.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 3) Legacy aliases (Unreal Engine lives) that pointed at an old-slug path -> new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Every old path of C437 -> new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c437_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c437_old;

-- -------------------------------------------------------- search redirects -----
UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, @new_slug, '.html')
 WHERE @ok AND store_id = 1 AND redirect = CONCAT(@base, @old_slug, '.html');

UPDATE catalogsearch_query
   SET redirect = CONCAT(@base, @new_slug, '.html')
 WHERE @ok AND store_id = 1 AND (redirect IS NULL OR redirect = '')
   AND query_text IN ('CCAR-F', 'ccarf', 'ccar', 'Claude Certified Architect - Foundations Certification',
                      'claude certified architect foundations');
