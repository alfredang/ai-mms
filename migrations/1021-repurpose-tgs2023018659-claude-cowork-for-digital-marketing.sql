-- 1021-repurpose-tgs2023018659-claude-cowork-for-digital-marketing.sql
--
-- REPURPOSE: TGS-2023018659
--   FROM "WSQ - Mastering Google Tag Manager for Optimized Website Tracking and Analytics"
--   TO   "WSQ - Claude Cowork for Digital Marketing"
--
-- CLASSIFICATION: repurpose (the VENDOR TOOL retires, the COMPETENCY stays).
--   skills_framework reads "System Integration ICT-DIT-3016-1.1 TSC" — the accredited
--   TSC is keyed on the UNCHANGED SKU and the new outline (MCP tool integration,
--   reusable Skills, marketing performance analysis) still delivers system integration.
--   The admin-supplied LOs are the LIVE LOs with only "Google Tag Manager"/"GTM"
--   removed, which confirms the realignment. Therefore:
--     * skills_framework block            -> NOT TOUCHED (TSC unchanged)
--     * certification block               -> NOT TOUCHED (OpenCerts on the same TSC)
--     * funding_and_grant block           -> NOT TOUCHED (keyed on unchanged SKU)
--     * prerequisite funding apparatus    -> NOT TOUCHED (only the tool <li> is retargeted)
--     * SKU / price / duration / sessions -> NOT TOUCHED
--
-- Surfaces changed: name, url_key, url_path (all scopes), meta_title, meta_description,
--   meta_keyword, short_description, description (+LSN_DATA), learning_outcomes block,
--   whoshouldattend, trainerprofile (course-teaching paragraphs only), prerequisite
--   (software <li> only), image/small_image/thumbnail labels, media gallery label,
--   301 for the old slug, category placements.
--
-- Idempotent: guarded by LOCATE()/NOT EXISTS so re-runs converge.
-- Partner-safe: TGS- SKUs exist only on SG; @e is NULL on MY/GH and every statement
--   is an UPDATE or a guarded INSERT, so partner deploys no-op instead of aborting.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023018659');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='name'             AND entity_type_id=4);
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key'          AND entity_type_id=4);
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path'         AND entity_type_id=4);
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_title'       AND entity_type_id=4);
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_description' AND entity_type_id=4);
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='meta_keyword'     AND entity_type_id=4);
SET @a_sd    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='short_description' AND entity_type_id=4);
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='description'      AND entity_type_id=4);
SET @a_wsa   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='whoshouldattend'  AND entity_type_id=4);
SET @a_tp    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='trainerprofile'   AND entity_type_id=4);
SET @a_pre   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='prerequisite'     AND entity_type_id=4);
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='image_label'       AND entity_type_id=4);
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='small_image_label' AND entity_type_id=4);
SET @a_tl    := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='thumbnail_label'   AND entity_type_id=4);

SET @newname := 'WSQ - Claude Cowork for Digital Marketing';
SET @plain   := 'Claude Cowork for Digital Marketing';
SET @newslug := 'wsq-claude-cowork-for-digital-marketing';
SET @oldslug := 'wsq-mastering-google-tag-manager-for-optimized-website-tracking-and-analytics';

-- ---------------------------------------------------------------- 1. name
UPDATE catalog_product_entity_varchar
   SET value = @newname
 WHERE entity_id = @e AND attribute_id = @a_name;

-- ---------------------------------------------------------------- 2. meta_title
-- Plain title only: MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs and appends
-- the brand postfix at render time. The OLD value baked in both ("WSQ course for ...
-- | Tertiary Courses Singapore") — the rename is the moment to fix that.
UPDATE catalog_product_entity_varchar
   SET value = 'Claude Cowork for Digital Marketing - Content, Automation and Analytics'
 WHERE entity_id = @e AND attribute_id = @a_mt;

-- ---------------------------------------------------------------- 3. meta_description
UPDATE catalog_product_entity_varchar
   SET value = 'Use Claude Cowork as an AI workspace for digital marketing - connect MCP tools, build reusable Claude Skills, and analyse campaign performance. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_md;

-- ---------------------------------------------------------------- 4. meta_keyword
UPDATE catalog_product_entity_text
   SET value = 'Claude Cowork, Digital Marketing, MCP Tools, Claude Skills, Marketing Automation, AI Content Creation, WSQ Funding, Marketing Analytics'
 WHERE entity_id = @e AND attribute_id = @a_mk;

-- ---------------------------------------------------------------- 5. url_key + url_path
-- New slug verified free: the sibling family owns wsq-claude-cowork-for-email-marketing
-- (TGS-2020503109) and claude-cowork-masterclass (C1382); neither collides.
UPDATE catalog_product_entity_varchar
   SET value = @newslug
 WHERE entity_id = @e AND attribute_id = @a_uk;

-- Drop url_path at EVERY scope so the URL Rewrites indexer regenerates it.
DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_up;

-- ---------------------------------------------------------------- 6. 301 old -> new
-- NOTE: the old bare slug is currently held by an is_system = 1 row. The unique key
-- UNQ_CORE_URL_REWRITE_REQUEST_PATH_STORE_ID is on (request_path, store_id) and does NOT
-- consider is_system, so the guard MUST test the path alone — an `is_system = 0` guard
-- passes and then dies on error 1062 (hit on the first dry-run of this file).
-- refreshProductRewrite($pid, 1) CONVERTS that system row into the RP 301 and mints the
-- new canonical row, so this INSERT is only for the case where no row holds the old path.
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, CONCAT('product/', @e, '-rp-1021'), CONCAT(@oldslug, '.html'), CONCAT(@newslug, '.html'), 0, 'RP'
  FROM dual
 WHERE @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) r
                    WHERE r.store_id = 1 AND r.request_path = CONCAT(@oldslug, '.html'));

-- ---------------------------------------------------------------- 7. short_description
-- Sections were extracted to cms_block rows (no "<h2>Course Brochure</h2>" tail here —
-- verified: the field is intro prose ONLY), so a full replace is correct.
-- Guarded on the new distinctive phrase for idempotency.
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<p>This hands-on course equips digital marketers with the skills to use Claude Cowork as an intelligent workspace for content production, system integration, workflow automation, and marketing performance analysis. Participants will learn how to connect Claude Cowork with various Model Context Protocol (MCP) tools, enabling it to access business applications, marketing platforms, documents, data sources, and other digital systems within a unified workflow.</p>',
     '<p>Learners will create reusable Claude Skills based on real-world marketing tasks, transforming proven work processes into repeatable AI-assisted workflows. These skills can support activities such as market research, campaign planning, audience profiling, SEO content creation, social media posts, email campaigns, advertising copy, content calendars, and marketing reports. Participants will also learn how to provide clear instructions, reference materials, brand guidelines, and quality criteria to produce consistent, brand-aligned content.</p>',
     '<p>The course further explores how Claude Cowork can consolidate campaign data, analyse key marketing metrics, identify performance trends, and generate actionable recommendations. Through practical exercises, participants will build integrated digital marketing workflows that reduce repetitive work, improve content quality, and support faster, data-driven decisions. By the end of the course, learners will be able to use Claude Cowork, MCP tools, and custom Skills to create a scalable and efficient AI-powered digital marketing system.</p>'
   )
 WHERE entity_id = @e AND attribute_id = @a_sd
   AND LOCATE('Claude Cowork as an intelligent workspace', value) = 0;

-- ---------------------------------------------------------------- 8. description (Course Outline)
-- The LSN_DATA JSON comment and the <p><strong>Topic N</strong></p> HTML must stay in sync.
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<!-- LSN_DATA: [{"title":"Topic 1: Integrating Claude Cowork with Digital Marketing Systems Using MCP Tools","subsecs":[]},{"title":"Topic 2: Creating Reusable Claude Skills for Digital Marketing Content and Workflows","subsecs":[]},{"title":"Topic 3: Analysing Marketing Performance and Generating Data-Driven Insights","subsecs":[]}] -->', CHAR(10),
     '<p><strong>Topic 1: Integrating Claude Cowork with Digital Marketing Systems Using MCP Tools</strong></p>', CHAR(10),
     '<p><strong>Topic 2: Creating Reusable Claude Skills for Digital Marketing Content and Workflows</strong></p>', CHAR(10),
     '<p><strong>Topic 3: Analysing Marketing Performance and Generating Data-Driven Insights</strong></p>', CHAR(10)
   )
 WHERE entity_id = @e AND attribute_id = @a_desc
   AND LOCATE('Integrating Claude Cowork with Digital Marketing Systems', value) = 0;

-- ---------------------------------------------------------------- 9. Learning Outcomes cms_block
-- Block exists (id 1764) — UPDATE is safe here. Content is the admin-supplied LO set,
-- which is the live SSG LO wording with the GTM product name removed.
UPDATE cms_block
   SET content = CONCAT(
     '<p>By the end of the course, learners will be able to&nbsp;</p>', CHAR(10),
     '<ul>', CHAR(10),
     '<li>LO1: Conduct a compatibility assessment and utilise essential tools to integrate with other systems.</li>', CHAR(10),
     '<li>LO2: Test system components and identify integration errors.</li>', CHAR(10),
     '<li>LO3: Propose potential changes through versioning and apply the best practices for integration.</li>', CHAR(10),
     '</ul>'
   )
 WHERE identifier = 'course_TGS-2023018659_learning_outcomes'
   AND LOCATE('utilise essential tools to integrate', content) = 0;

-- ---------------------------------------------------------------- 10. whoshouldattend
-- Repurpose surface: the job-role list named the OLD TECHNOLOGY. Retarget each role at
-- its AI-marketing equivalent; keep the roles that are tool-neutral.
UPDATE catalog_product_entity_text
   SET value = CONCAT(
     '<ul>', CHAR(10),
     '<li>Digital Marketer</li>', CHAR(10),
     '<li>Marketing Executive</li>', CHAR(10),
     '<li>Content Marketing Specialist</li>', CHAR(10),
     '<li>Social Media Manager</li>', CHAR(10),
     '<li>SEO Specialist</li>', CHAR(10),
     '<li>Email Marketing Specialist</li>', CHAR(10),
     '<li>Marketing Automation Specialist</li>', CHAR(10),
     '<li>Marketing Technology Specialist</li>', CHAR(10),
     '<li>Campaign Manager</li>', CHAR(10),
     '<li>Brand Manager</li>', CHAR(10),
     '<li>E-commerce Manager</li>', CHAR(10),
     '<li>Marketing Analyst</li>', CHAR(10),
     '<li>Content Strategist</li>', CHAR(10),
     '<li>Growth Marketing Specialist</li>', CHAR(10),
     '<li>Marketing Operations Executive</li>', CHAR(10),
     '</ul>'
   )
 WHERE entity_id = @e AND attribute_id = @a_wsa
   AND LOCATE('Marketing Automation Specialist', value) = 0;

-- ---------------------------------------------------------------- 11. prerequisite
-- ONLY the "Minimum Software/Hardware Requirement" tool links are retargeted. The rest of
-- this blob holds the ENTIRE funding apparatus (PWM, Funding Eligibility table,
-- SkillsFuture/PSEA/SFEC/UTAP deep links, Appeal Process) and must never be rewritten
-- wholesale. Targeted REPLACE() on the exact <li> strings only.
UPDATE catalog_product_entity_text
   SET value = REPLACE(
        REPLACE(
          REPLACE(value,
            '<li><a href="https://tagmanager.google.com/" target="_blank"><span style="text-decoration: underline;">Google Tag Manager</span></a></li>',
            '<li><a href="https://claude.ai/" target="_blank"><span style="text-decoration: underline;">Claude Cowork</span></a></li>'),
          '<li><a href="https://analytics.google.com/" target="_blank"><span style="text-decoration: underline;">Google Analytics</span></a></li>',
          '<li><a href="https://modelcontextprotocol.io/" target="_blank"><span style="text-decoration: underline;">Model Context Protocol (MCP) Tools</span></a></li>'),
        'Sign up for free <a href="https://accounts.google.com/signup" target="_blank">Google account</a>',
        'Sign up for a <a href="https://claude.ai/" target="_blank">Claude account</a>')
 WHERE entity_id = @e AND attribute_id = @a_pre;

-- ---------------------------------------------------------------- 12. trainerprofile
-- Retarget ONLY the course-teaching paragraph of each bio. Career-history CREDENTIALS
-- (real GA/GTM consulting experience) are FACTS and stay — rewriting them would falsify
-- the bio. Pass condition after apply: remaining GTM mentions all sit in para 1.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
     '<p>In &ldquo;Mastering Google Tag Manager for Optimized Website Tracking and Analytics,&rdquo; Lynn focuses on enabling participants to take full control of their website data through effective tag deployment, event tracking, and advanced analytics integration. Her sessions emphasize practical, hands-on applications of GTM&mdash;covering data layer design, trigger configuration, and custom event tracking for Google Analytics 4. By combining her technical expertise with real-world digital strategy, she equips learners to implement scalable, precise, and compliant data tracking strategies that empower smarter business decisions.</p>',
     '<p>In &ldquo;Claude Cowork for Digital Marketing,&rdquo; Lynn focuses on enabling participants to connect Claude Cowork with their marketing platforms and data sources through MCP tools, so campaign data, documents, and reporting systems work within one AI-assisted workflow. Her sessions emphasize practical, hands-on integration&mdash;covering compatibility assessment, testing integrated components, and building reusable Claude Skills for research and reporting. By combining her technical expertise with real-world digital strategy, she equips learners to turn proven marketing processes into repeatable, data-driven AI workflows.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
     '<p>In &ldquo;Mastering Google Tag Manager for Optimized Website Tracking and Analytics,&rdquo; Teddy provides learners with a systematic understanding of GTM setup, tag governance, and performance optimization. His sessions focus on integrating GTM with various marketing and analytics platforms, ensuring accurate data flow and efficient tag management across complex digital ecosystems. Drawing from his extensive project experience, he helps participants design streamlined, secure, and scalable tracking infrastructures that enhance data reliability and marketing performance measurement.</p>',
     '<p>In &ldquo;Claude Cowork for Digital Marketing,&rdquo; Teddy provides learners with a systematic understanding of MCP tool integration, versioning, and workflow governance. His sessions focus on connecting Claude Cowork with various marketing and business platforms, ensuring accurate data flow and reliable automation across complex digital ecosystems. Drawing from his extensive project experience, he helps participants design streamlined, secure, and scalable AI-assisted marketing workflows that enhance data reliability and performance measurement.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
     '<p>His expertise in website tracking, analytics, and optimization makes him well-positioned to train learners in Google Tag Manager (GTM). Raymond emphasizes real-world applications, showing participants how to configure tags, triggers, and variables to capture actionable insights. With his strong background in campaign management and analytics, he equips learners to optimize website performance, improve ROI, and align GTM with broader digital strategies.</p>',
     '<p>His expertise in campaign management, analytics, and optimization makes him well-positioned to train learners in Claude Cowork for digital marketing. Raymond emphasizes real-world applications, showing participants how to build reusable Claude Skills for market research, campaign planning, and content production. With his strong background in performance marketing, he equips learners to consolidate campaign data, improve ROI, and align AI-assisted workflows with broader digital strategies.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
     '<p>An ACLP-certified trainer, Allen specializes in simplifying complex analytics workflows for learners. He provides hands-on guidance in using GTM to manage tracking codes, set up event tracking, and integrate with platforms like Google Analytics and advertising tools. His learner-focused approach ensures participants not only understand the technical setup but also gain the confidence to apply GTM for optimizing digital campaigns and website performance.</p>',
     '<p>An ACLP-certified trainer, Allen specializes in simplifying complex marketing workflows for learners. He provides hands-on guidance in using Claude Cowork to connect MCP tools, automate repetitive campaign tasks, and produce brand-aligned content at scale. His learner-focused approach ensures participants not only understand the technical setup but also gain the confidence to apply Claude Cowork for optimizing digital campaigns and marketing performance.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
     '<p>Her corporate background includes leading global marketing initiatives at Creative Technology, where she drove significant online sales and customer engagement. As a trainer, Janice emphasizes practical learning, showing participants how GTM can simplify tracking implementation, improve data accuracy, and enhance website performance analysis. Her ability to connect digital strategy with technical execution ensures learners can confidently apply GTM to optimize their organizations&rsquo; online presence and analytics capabilities.</p>',
     '<p>Her corporate background includes leading global marketing initiatives at Creative Technology, where she drove significant online sales and customer engagement. As a trainer, Janice emphasizes practical learning, showing participants how Claude Cowork can simplify content production, improve consistency through reusable Skills, and enhance marketing performance analysis. Her ability to connect digital strategy with technical execution ensures learners can confidently apply Claude Cowork to optimize their organizations&rsquo; marketing workflows and reporting.</p>')
 WHERE entity_id = @e AND attribute_id = @a_tp;

-- ---------------------------------------------------------------- 13. alt-text labels
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
-- NOTE: image/small_image/thumbnail hold the uploaded JPG's FILESYSTEM PATH and are
-- deliberately NOT renamed — renaming them 404s the file.
UPDATE catalog_product_entity_varchar SET value = @plain
 WHERE entity_id = @e AND attribute_id IN (@a_il, @a_sil, @a_tl);

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @plain
 WHERE g.entity_id = @e;

-- ---------------------------------------------------------------- 14. brochure block title
UPDATE cms_block
   SET title = 'Course Brochure - TGS-2023018659'
 WHERE identifier = 'course_TGS-2023018659_brochure';

-- ---------------------------------------------------------------- 15. category placements
-- DROP the pure Google/GTM-tool listings — the course no longer teaches that toolchain.
-- The non-WSQ twin C484 "Google Tag Manager (GTM) Essential Training" stays live and
-- continues to serve GTM-intent browsing, so these listings lose nothing.
--   67  Google              239 Google Analytics
--   22  SEO                 36  PPC Marketing
--   235 Google Tag Manager (not currently a member; included for convergence)
DELETE cp FROM catalog_category_product cp
 WHERE cp.product_id = @e AND cp.category_id IN (22, 36, 67, 235, 239);

DELETE ci FROM catalog_category_product_index ci
 WHERE ci.product_id = @e AND ci.category_id IN (22, 36, 67, 235, 239);

-- KEEP: 3 All Courses, 8 Digital Marketing, 15 WSQ and IBF, 53 Software Training,
--       72 WSQ Media & Marketing, 292 WSQ Funded, 293/301/307 WSQ listings,
--       308 WSQ Digital Marketing — the course is still a WSQ digital-marketing course.

-- ADD the AI / Claude listings its sibling family sits in (resolved by NAME so the
-- statement is portable; append at MAX(position)+1 for the ordering sweep).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.entity_id, @e, COALESCE((SELECT MAX(x.position) + 1 FROM (SELECT * FROM catalog_category_product) x
                                   WHERE x.category_id = c.entity_id), 1)
  FROM catalog_category_entity_varchar c
 WHERE c.store_id = 0
   AND c.attribute_id = (SELECT attribute_id FROM eav_attribute
                          WHERE attribute_code = 'name'
                            AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type
                                                   WHERE entity_type_code = 'catalog_category'))
   AND c.value IN ('AI Courses', 'Claude AI Series', 'WSQ AI Courses')
   AND @e IS NOT NULL;

-- Mirror the additions into the category index or the storefront listings never change.
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  CROSS JOIN (SELECT store_id FROM core_store WHERE store_id > 0) s
 WHERE cp.product_id = @e
   AND cp.category_id IN (
        SELECT c.entity_id FROM catalog_category_entity_varchar c
         WHERE c.store_id = 0
           AND c.attribute_id = (SELECT attribute_id FROM eav_attribute
                                  WHERE attribute_code = 'name'
                                    AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type
                                                           WHERE entity_type_code = 'catalog_category'))
           AND c.value IN ('AI Courses', 'Claude AI Series', 'WSQ AI Courses'))
   AND @e IS NOT NULL;
