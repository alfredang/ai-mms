-- 1020: TGS-2025056988 "WSQ - Agentic AI for Digital Marketing"
--       CONTENT UPDATE -- re-anchor the course onto Claude Cowork, MCP tools and
--       custom Claude Skills.
--
-- This is NOT a rename and NOT a repurpose:
--   * `name` is unchanged ("WSQ - Agentic AI for Digital Marketing") -- so there is
--     no url_key change, no 301, no *_label / media_gallery alt-text edit.
--     [[feedback_title_only_rename_vs_repurpose_scope]]
--   * The SUBJECT is unchanged (digital marketing strategy, ROI, multi-channel
--     online presence). The accredited TSC block reads
--     "Digital Marketing-5 WST-SNM-5042-1.1 TSC under Wholesale Trade Skills
--     Framework" -- keyed on the UNCHANGED SKU, so the competency stays and the
--     skills_framework cms_block (2879) is deliberately NOT touched.
--     [[feedback_repurpose_realigns_to_own_accredited_tsc]]
--
-- What actually changes is the TOOLING the competency is taught through:
-- generic "Gen AI / prompt engineering" -> Claude Cowork as a marketing
-- workspace + MCP integrations + custom Claude Skills. That lands in exactly
-- four surfaces:
--
--   1. course outline      catalog_product_entity_text.attribute_id = 72  (description)
--   2. about this course   catalog_product_entity_text.attribute_id = 73  (short_description)
--   3. learning outcomes   cms_block 'course_TGS-2025056988_learning_outcomes'
--   4. meta_description + meta_keyword (they name the retired Gen-AI framing)
--
-- `meta_title` is ALSO stale (it still names the retired "Formulate Digital
-- Marketing Strategy with AI Agent and Deep Research" title) but is fixed in the
-- follow-up file 1022 -- this file was already ledgered by a concurrent apply.php
-- run before that statement was written, so it could never execute here.
--
-- Untouched on purpose: name, url_key/url_path, categories, whoshouldattend
-- (all 20 roles still describe this course), prerequisite (entry requirements +
-- PWM + funding criteria are SSG boilerplate), trainerprofile, duration (16h),
-- sessions (2), cover image, the funding_and_grant + skills_framework blocks.
--
-- The outline collapses from 3 Learning Units / 10 sub-topics to the 3 topics the
-- admin supplied. Same shape as migration 1003 (TGS-2022015374): the LSN_DATA
-- JSON marker and the visible <p><strong>Topic N HTML are rebuilt TOGETHER so the
-- admin Lesson editor (dashboard/index.phtml, the /<!--\s*LSN_DATA:\s*(\[.*?\])\s*-->/
-- parser) and the storefront "What You'll Learn" card never disagree.
--
-- Partner-safe: TGS- SKUs exist only on SG, so @e IS NULL on MY/GH and every
-- statement below is a guarded no-op there. Fully idempotent -- re-runnable.
-- Pure ASCII (no smart quotes / en-dashes) so apply.php's utf8 PDO connection
-- cannot trip error 1366. [[feedback_migration_applyphp_utf8_outage]]

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025056988' LIMIT 1);

-- ---------------------------------------------------------------- 1. course outline
-- Old value: LU1/LU2/LU3 with 10 T1..T4 sub-topics, framed on "Gen AI Deep Research"
-- and "GenAI prompt engineering". Replaced by the 3 supplied Claude Cowork topics.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 72, 0, @e,
'<!-- LSN_DATA: [{"title":"Topic 1: Digital Marketing Research and Campaign Planning with Claude Cowork","subsecs":[]},{"title":"Topic 2: Creating Multi-Channel Marketing Content with Custom Claude Skills","subsecs":[]},{"title":"Topic 3: Integrating MCP Tools and Analysing Digital Marketing Performance","subsecs":[]}] -->
<p><strong>Topic 1: Digital Marketing Research and Campaign Planning with Claude Cowork</strong></p>
<p><strong>Topic 2: Creating Multi-Channel Marketing Content with Custom Claude Skills</strong></p>
<p><strong>Topic 3: Integrating MCP Tools and Analysing Digital Marketing Performance</strong></p>'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 72 AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------- 2. about this course
-- Admin-supplied "About This Course" prose, verbatim, one <p> per paragraph.
-- Note the old value carried a mojibake byte ("today's" stored as today\x92s);
-- this rewrite replaces the whole value with clean ASCII.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 73, 0, @e,
'<p>This course equips learners with practical skills to use Claude Cowork and agentic AI to plan, create, manage, and optimise digital marketing activities across multiple channels. Participants will learn how to use Claude Cowork as an intelligent marketing workspace for conducting market research, understanding target audiences, developing campaign strategies, coordinating tasks, and producing consistent, brand-aligned marketing content.</p>
<p>Learners will explore how Model Context Protocol (MCP) tools can connect Claude Cowork with relevant business applications, documents, data sources, content repositories, and marketing platforms. These integrations enable Claude Cowork to retrieve information, work across systems, and support end-to-end digital marketing workflows with appropriate human oversight.</p>
<p>The course also guides participants in creating custom Claude Skills from real-world marketing processes. Learners will transform repeatable tasks, brand guidelines, templates, and quality standards into reusable skills for campaign planning, content creation, review, reporting, and optimisation. They will apply these skills to produce channel-specific content for websites, blogs, search engines, email campaigns, social media, online advertisements, and other digital touchpoints.</p>
<p>Participants will also use Claude Cowork to analyse campaign results, compare performance against marketing objectives and KPIs, identify trends, evaluate return on investment, and generate actionable recommendations. By the end of the course, learners will be able to build integrated, AI-assisted digital marketing workflows that improve productivity, content consistency, audience engagement, and data-driven decision-making.</p>
<p>This course is suitable for beginner and intermediate learners who have a basic understanding of digital marketing and want to apply Claude Cowork, MCP integrations, and custom AI skills in practical marketing environments.</p>'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 73 AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------- 3. learning outcomes
-- The LO cms_block feeds the primary-column "Learning Outcomes" card. LO wording is
-- taken from the admin verbatim (these are the SSG-registered outcomes -- do not
-- paraphrase). LO2 and LO3 are unchanged in substance from the live block; LO1 is
-- restated to lead with Gen AI Deep Research for strategy AND ROI.
--
-- Guarded INSERT first: on a rebuilt DB the block may not exist, and a bare UPDATE
-- would silently no-op. cms_block.identifier has NO unique key, so the INSERT is
-- gated on a NOT EXISTS probe rather than INSERT IGNORE.
-- [[feedback_cms_block_identifier_has_no_unique_key]]
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2025056988 - Learning Outcomes',
       'course_TGS-2025056988_learning_outcomes',
       '', NOW(), NOW(), 1
FROM dual
WHERE NOT EXISTS (
    SELECT 1 FROM (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2025056988_learning_outcomes') x
);

SET @lo := (SELECT block_id FROM cms_block WHERE identifier = 'course_TGS-2025056988_learning_outcomes' ORDER BY block_id LIMIT 1);

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT @lo, 0 FROM dual WHERE @lo IS NOT NULL;

UPDATE cms_block
SET content = '<p>By the end of the course, learners will be able to:</p><ul><li>LO1: Using Gen AI Deep Research to formulate digital marketing strategy and ROI</li><li>LO2: Evaluate digital marketing ROI and synthesize strategy models to align with overarching marketing objectives.</li><li>LO3: Lead the creation of an integrated online presence across emerging multiple digital channels</li></ul>',
    is_active = 1,
    update_time = NOW()
WHERE block_id = @lo AND @lo IS NOT NULL;

-- ---------------------------------------------------------------- 4. meta_description
-- varchar(255) hard cap -- the string below is 154 chars.
-- [[feedback_meta_description_255_char_cap]]
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 84, 0, @e,
'Plan, create and optimise multi-channel digital marketing with Claude Cowork, MCP tools and custom Claude Skills. Up to 70% WSQ funding subsidy.'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = 84 AND store_id <> 0 AND @e IS NOT NULL;

-- ---------------------------------------------------------------- 5. meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 83, 0, @e,
'Claude Cowork digital marketing, agentic AI marketing, MCP tools marketing, custom Claude Skills, AI campaign planning, multi-channel marketing content, digital marketing ROI, WSQ digital marketing course, AI marketing workflow, Singapore WSQ courses'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND attribute_id = 83 AND store_id <> 0 AND @e IS NOT NULL;
