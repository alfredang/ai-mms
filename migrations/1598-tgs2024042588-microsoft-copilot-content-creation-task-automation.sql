-- 1598: TGS-2024042588 "WSQ - Copilot for Power Automate" ->
--       "WSQ - Microsoft Copilot for Content Creation and Task Automation"
--
-- Admin request 2026-09-29: new title, About, LO1-LO4, four-topic outline,
-- new cover image and new URL slug. The SKU and the accredited TSC
-- (skills_framework block: "Applications Integration ICT-DIT-3003-1.1") are
-- UNCHANGED, so every SkillsFuture / SFEC / SFC / PSEA deep link, the
-- funding_and_grant block, the 6 funding tags, price ($2,500), duration (40)
-- and sessions (5) all stay.
--
-- Pre-write probe (SG prod, entity 1467): this entity has had three lives --
-- "WSQ - Microsoft Power Platform Functional Consultant (PL-200)" -> "WSQ -
-- Copilot for Power Automate" -> this one. Surfaces that change here:
--   name, url_key/url_path, meta_title/description/keyword (store 0 AND 1
--   rows), short_description, description (outline), the learning_outcomes
--   block (still PL-200 era: dataverse / Power Virtual Agent / AI Builder),
--   whoshouldattend (15 developer roles), prerequisite software (still
--   "Power BI Desktop" from the PL-200 life), the course-teaching paragraph
--   of all 5 trainer bios, 3 alt labels + gallery label, the cover, the
--   Power Automate + Certification Exam Prep categories, search redirects
--   and two blog-post links.
--
-- Deliberately NOT touched: brochure / funding_and_grant / skills_framework /
-- certification blocks; trainer bio CREDENTIAL paragraphs (career facts);
-- image / small_image / thumbnail PATHS (renaming 404s the file); the 3
-- learner reviews (generic, no old-topic text); categories 345 WSQ
-- Certification Courses (sibling Copilot course TGS-2024044051 sits there
-- too) and 293 / 301 funding listings.
--
-- SLUG: `wsq-microsoft-copilot-for-content-creation-and-task-automation` --
-- no product url_key and no core_url_rewrite row on the new path. The old
-- bare slug 301s to it, and the ~40 pre-existing 301s from the PL-200 and
-- Copilot-for-Power-Automate lives (bare + category-prefixed) are flattened
-- to the new bare slug in ONE hop. No other product's slug ends in
-- `wsq-copilot-for-power-automate.html`.
--
-- COVER: re-rendered on the SG web container via MMD_CourseImage_Model_Cover
-- with the product's own badges (WSQ, SkillsFuture Credit, PSEA, SFEC,
-- Absentee Payroll, MCES) and uploaded before this file was written:
--   course-covers/TGS-2024042588-20260929-072205.png  (193553 bytes, HTTP 200)
-- The superseded object stays on R2, so reverting is just repointing the URL.
--
-- POST-DEPLOY (code paths a migration cannot run, on the SG web container):
--   1. Mage::getSingleton('catalog/url')->refreshProductRewrite(1467), then
--      catalog_product_flat reindex + cache flush -- the NEW slug 404s until
--      this runs, even though the old slug already 301s.
--   2. scripts/seo/generate-sitemaps.php so the sitemap lists the new slug.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2024042588
-- no-ops. Idempotent: plain UPDATEs, INSERT IGNORE, self-extinguishing
-- REPLACE()s.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024042588' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------------------
-- 1. Identity: name, url_key, url_path
-- ---------------------------------------------------------------------------

-- name: keeps the `WSQ - ` prefix (the storefront H1 wants it)
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'name' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Microsoft Copilot for Content Creation and Task Automation'
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_key' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-microsoft-copilot-for-content-creation-and-task-automation'
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

-- url_path: DELETE at every scope (store 0 AND store 1 rows exist) so the URL
-- Rewrites indexer regenerates it
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_path' AND entity_type_id = @et);
DELETE FROM catalog_product_entity_varchar
 WHERE attribute_id = @a_upath AND entity_id = @e AND @e IS NOT NULL AND @a_upath IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. Meta (store 0 and store 1 rows both exist; update every scope)
-- ---------------------------------------------------------------------------

-- meta_title: PLAIN title -- MMD_Seotitle adds "WSQ funded" + brand at render
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_title' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'Microsoft Copilot for Content Creation and Task Automation'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- meta_description: varchar(255) -- this value is 211 chars
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_description' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'Use Microsoft Copilot to create emails, reports, proposals and presentations, summarise documents and meetings, and automate routine tasks across Microsoft 365 with responsible AI. Up to 70% WSQ funding subsidy.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_keyword' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = 'Microsoft Copilot for Content Creation and Task Automation, Microsoft Copilot course Singapore, WSQ Copilot course, Copilot content creation, Copilot prompt writing, Microsoft 365 Copilot productivity, AI task automation, Copilot email and report writing, Copilot meeting summaries, AI-assisted workflows, responsible AI, WSQ funded Copilot course'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Content: About, Course Outline, Learning Outcomes, audience, software
-- ---------------------------------------------------------------------------

-- short_description ("What's This Course About"): the supplied five-paragraph
-- narrative. This course's other sections live in cms_block rows, so
-- short_description holds ONLY the intro copy -- a full replace is correct.
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'short_description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<p>Microsoft Copilot for Content Creation and Task Automation is a practical, hands-on course designed to help participants use Microsoft Copilot and AI-powered tools to create professional content, automate routine tasks, and improve workplace productivity.</p>',
'\n<p>Participants will learn how to write effective prompts and use Copilot to generate, rewrite, summarise, and enhance different types of business content, including emails, reports, proposals, presentations, meeting notes, and other workplace communications. The course introduces practical techniques for refining AI-generated content to improve clarity, tone, accuracy, and relevance for different audiences and business needs.</p>',
'\n<p>The course also explores how Microsoft Copilot can support task automation and everyday workflows. Participants will learn to use AI to organise information, summarise documents and conversations, extract key actions, analyse workplace information, prepare follow-up content, and streamline repetitive administrative tasks across Microsoft 365 applications.</p>',
'\n<p>Through hands-on activities and workplace scenarios, participants will apply Copilot to real-world content creation and productivity tasks while learning how to review and validate AI-generated outputs. Emphasis is placed on responsible AI use, data privacy, accuracy, and maintaining appropriate human oversight.</p>',
'\n<p>By the end of the course, participants will be able to use Microsoft Copilot more effectively to produce high-quality workplace content, automate common tasks, reduce manual effort, and develop more efficient AI-assisted workflows.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- description (Course Outline): LSN_DATA JSON + rendered markup in the shape
-- the admin outline editor writes. Four topic titles, empty subsecs.
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: Microsoft Copilot Opportunity Identification and Feasibility Assessment","subsecs":[]},{"title":"Topic 2: Microsoft Copilot Integration and Task Automation","subsecs":[]},{"title":"Topic 3: Microsoft Copilot Testing and Cross-Platform Validation","subsecs":[]},{"title":"Topic 4: Microsoft Copilot Modification and Technical Troubleshooting","subsecs":[]}] -->',
'\n<p><strong>Topic 1: Microsoft Copilot Opportunity Identification and Feasibility Assessment</strong></p>',
'\n<p><strong>Topic 2: Microsoft Copilot Integration and Task Automation</strong></p>',
'\n<p><strong>Topic 3: Microsoft Copilot Testing and Cross-Platform Validation</strong></p>',
'\n<p><strong>Topic 4: Microsoft Copilot Modification and Technical Troubleshooting</strong></p>',
'\n')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

-- What You'll Learn: the supplied LO1-LO4 (block exists on prod, id 1960).
UPDATE cms_block
   SET content = CONCAT(
'<p>By end of the course, learners should be able to:</p>',
'\n<ul>',
'\n<li>LO1: Identify opportunities and perform feasibility scans for Microsoft Copilot applications.</li>',
'\n<li>LO2: Utilise Microsoft Copilot to integrate functions across programs with API-level integration.</li>',
'\n<li>LO3: Execute tests in Microsoft Copilot to verify their functioning across platforms.</li>',
'\n<li>LO4: Implement modifications to Microsoft Copilot to highlight technical issues.</li>',
'\n</ul>'),
       update_time = NOW()
 WHERE identifier = 'course_TGS-2024042588_learning_outcomes';

-- whoshouldattend: the 15 developer roles described the PL-200 / Power
-- Platform course. The new course is for business users who produce content
-- and run routine workflows, plus the IT roles the Applications Integration
-- TSC still serves.
SET @a_wsa := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'whoshouldattend' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = '<ul><li>Executives and Administrative Officers</li><li>Business and Operations Managers</li><li>Marketing and Communications Executives</li><li>Content Creators</li><li>Project Managers</li><li>Business Analysts</li><li>HR and Finance Executives</li><li>Sales Executives</li><li>Microsoft 365 Power Users</li><li>IT Consultant</li><li>Systems Analyst</li><li>Application Developer</li><li>Solutions Architect</li></ul>'
 WHERE attribute_id = @a_wsa AND entity_id = @e AND @e IS NOT NULL;

-- prerequisite ("Minimum Software/Hardware Requirement"): still listed Power
-- BI Desktop + a Power BI account from the PL-200 life. This blob is ALSO the
-- whole funding apparatus (PWM, eligibility, Appeal Process), so only the
-- software/hardware lines are swapped; the REPLACE no-ops once applied.
SET @a_pre := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'prerequisite' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<p>You can download and install the following software:</p><ul><li><u><a href="https://powerbi.microsoft.com/en-us/downloads/" rel="noopener noreferrer" target="_blank">Power BI Desktop</a></u></li></ul><p>You can also sign up a <u><a href="https://app.powerbi.com/" rel="noopener noreferrer" target="_blank">Power BI account</a></u></p><p><strong>Hardware:</strong> Window Laptop</p>',
       CONCAT('<p>You will need access to the following software:</p><ul>',
              '<li><a href="https://www.microsoft.com/en-us/microsoft-365/copilot" target="_blank"><span style="text-decoration: underline;">Microsoft 365 Copilot</span></a></li>',
              '</ul><p><strong>Hardware:</strong> Windows and Mac Laptops</p>'))
 WHERE attribute_id = @a_pre AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. Trainer bios: retarget ONLY the course-teaching paragraph of each of the
--    5 bios (all describe Copilot Studio + Power Automate agents). The
--    credential paragraphs are career facts and stay.
-- ---------------------------------------------------------------------------
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'trainerprofile' AND entity_type_id = @et);

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Sanjiv provides practical insights into designing Copilot Studio agents, automating business processes with Power Automate, and integrating agentic workflows across enterprise systems. His sessions emphasize security, governance, and scalability, helping participants design robust agentic automation solutions aligned with modern organizational needs.',
       'In this course, Sanjiv provides practical insights into using Microsoft Copilot to create business content, automate routine tasks, and integrate AI-assisted workflows across Microsoft 365 applications. His sessions emphasize security, governance, and responsible AI use, helping participants design robust AI-assisted workflows aligned with modern organizational needs.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Eugene focuses on enabling learners to design end-to-end agentic automation solutions and natural-language business agents. His training integrates real-world use cases that demonstrate how conversational interfaces and workflow automation can enhance productivity and operational transparency. He empowers participants to apply Copilot Studio and Power Automate effectively to drive organizational efficiency and innovation.',
       'In this course, Eugene focuses on enabling learners to use Microsoft Copilot to generate, refine, and summarise workplace content and to streamline everyday tasks. His training integrates real-world use cases that demonstrate how effective prompting and AI-assisted workflows can enhance productivity and operational transparency. He empowers participants to apply Microsoft Copilot effectively to drive organizational efficiency and innovation.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Bernard guides participants through building and deploying Copilot Studio agents and the Power Automate workflows behind them. His sessions emphasize conversation design, integration with business data and APIs, and governance best practices. Through hands-on exercises, he equips professionals with the ability to deliver scalable agentic automation that streamlines operations and improves decision-making.',
       'In this course, Bernard guides participants through using Microsoft Copilot to draft emails, reports, proposals, and presentations and to automate routine administrative tasks. His sessions emphasize prompt writing, integration with business data across Microsoft 365, and governance best practices. Through hands-on exercises, he equips professionals with the ability to deliver AI-assisted workflows that streamline operations and improve decision-making.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Truman focuses on teaching participants how to design secure, high-performance agentic automation within hybrid environments. His sessions cover API and system integration, data security, human approval checkpoints, and automation orchestration. Through his systems-engineering approach, he enables learners to design intelligent workflows that optimize operations and drive digital transformation.',
       'In this course, Truman focuses on teaching participants how to use Microsoft Copilot securely for content creation and task automation across platforms. His sessions cover API-level integration, cross-platform testing, data privacy, and human oversight of AI-generated outputs. Through his systems-engineering approach, he enables learners to design intelligent workflows that optimize operations and drive digital transformation.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Audrey teaches participants how to design Copilot Studio conversation topics, automate the work behind them with Power Automate, and return useful results to users. Her sessions focus on problem-solving, process optimization, and testing. Drawing from her project management and instructional experience, she helps learners confidently apply Copilot Studio and Power Automate to analyze business needs and implement scalable, user-focused agentic solutions.',
       'In this course, Audrey teaches participants how to write effective prompts in Microsoft Copilot, refine AI-generated content for different audiences, and turn meetings and documents into clear summaries and follow-up actions. Her sessions focus on problem-solving, process optimization, and testing. Drawing from her project management and instructional experience, she helps learners confidently apply Microsoft Copilot to analyze business needs and implement scalable, user-focused AI-assisted solutions.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. Cover image + alt text
-- ---------------------------------------------------------------------------

-- alt-text labels: plain title, no `WSQ - ` prefix
UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
    SET v.value = 'Microsoft Copilot for Content Creation and Task Automation'
  WHERE v.entity_id = @e AND @e IS NOT NULL
    AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label');

-- media gallery label -- the real alt text on the product image (the stored
-- file PATH is left alone: renaming it 404s the file)
UPDATE catalog_product_entity_media_gallery_value gv
   JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
    SET gv.label = 'Microsoft Copilot for Content Creation and Task Automation'
  WHERE g.entity_id = @e AND @e IS NOT NULL;

-- cover image: repoint at the regenerated PNG (global scope; clear any
-- store-scoped row that would shadow it)
SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'course_image_url' AND entity_type_id = @et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024042588-20260929-072205.png'
  WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0
   AND @e IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. Categories: the course no longer teaches Power Automate (107) or preps
--    an exam (182); it belongs in GenAI Content Creation (200). Mirrored into
--    catalog_category_product_index: 218 Power Platform was reached only via
--    107, and 433 Generative AI Series is the anchor parent of 200 (11/53
--    stay via 137 Microsoft Copilot; 252 is already a direct member).
-- ---------------------------------------------------------------------------
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (107, 182) AND @e IS NOT NULL;
DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (107, 182, 218) AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 200, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = 200), 0) + 1
  FROM catalog_category_entity c
 WHERE c.entity_id = 200 AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, @e, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  JOIN core_store s ON s.store_id > 0
 WHERE cp.category_id = 200 AND cp.product_id = @e AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 433, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product_index WHERE category_id = 433), 0) + 1, 0, s.store_id, 4
  FROM core_store s
  JOIN catalog_category_entity c ON c.entity_id = 433
 WHERE s.store_id > 0 AND @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_product WHERE category_id = 200 AND product_id = @e);

-- ---------------------------------------------------------------------------
-- 7. URL rewrites: 301 the old slug, flatten the chain history
-- ---------------------------------------------------------------------------
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- The old bare slug is held by the canonical is_system=1 row on
-- id_path='product/<e>'. INSERT IGNORE would silently no-op against it, so
-- DELETE it first; refreshProductRewrite re-mints the canonical row at the
-- NEW slug post-deploy.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1
   AND request_path = 'wsq-copilot-for-power-automate.html'
   AND @e IS NOT NULL;

-- Clear any is_system=0 squatter sitting on the NEW path
DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-microsoft-copilot-for-content-creation-and-task-automation.html'
   AND is_system = 0;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid, CONCAT('tgs2024042588-copilot-content-bare-', @e),
       'wsq-copilot-for-power-automate.html',
       'wsq-microsoft-copilot-for-content-creation-and-task-automation.html',
       0, 'RP', '1598: TGS-2024042588 renamed to Microsoft Copilot for Content Creation and Task Automation'
 WHERE @e IS NOT NULL AND @sid IS NOT NULL;

-- Flatten the PRE-EXISTING 301s that point at the old slug, bare or
-- category-prefixed (the indexer never regenerates the latter, so they would
-- 301 -> 404), to the new BARE slug in one hop.
UPDATE core_url_rewrite
   SET target_path = 'wsq-microsoft-copilot-for-content-creation-and-task-automation.html'
 WHERE is_system = 0
   AND target_path LIKE '%wsq-copilot-for-power-automate.html'
   AND id_path NOT LIKE 'tgs2024042588-copilot-content-%';

-- ---------------------------------------------------------------------------
-- 8. Search-term redirects (SG data; partner sites have no matching rows)
-- ---------------------------------------------------------------------------

-- PL-200 / Power Platform functional-consultant intent: this course has not
-- been PL-200 since its previous life, and the PL-200 product (C405) is
-- disabled -> the Power Platform category page (200 verified).
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/microsoft-power-platform-software-training-courses.html'
 WHERE redirect LIKE '%wsq-microsoft-power-platform-functional-consultant-pl-200.html'
   AND query_text <> 'TGS-2024042588';

-- The course code follows the course.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-microsoft-copilot-for-content-creation-and-task-automation.html'
 WHERE query_text = 'TGS-2024042588';

-- ---------------------------------------------------------------------------
-- 9. Blog posts linking the old title (142 Microsoft 365 Copilot guide, 143
--    Power Automate + Copilot Studio worked example)
-- ---------------------------------------------------------------------------
UPDATE mmd_blog_post
   SET content = REPLACE(content,
       '<a href="https://www.tertiarycourses.com.sg/wsq-copilot-for-power-automate.html">Copilot for Power Automate</a> if you want Copilot to write the flows for you',
       '<a href="https://www.tertiarycourses.com.sg/wsq-microsoft-copilot-for-content-creation-and-task-automation.html">Microsoft Copilot for Content Creation and Task Automation</a> if you want Copilot to draft your everyday content and automate routine tasks')
 WHERE post_id = 143;

UPDATE mmd_blog_post
   SET content = REPLACE(content,
       '<a href="https://www.tertiarycourses.com.sg/wsq-copilot-for-power-automate.html">Copilot for Power Automate</a>',
       '<a href="https://www.tertiarycourses.com.sg/wsq-microsoft-copilot-for-content-creation-and-task-automation.html">Microsoft Copilot for Content Creation and Task Automation</a>')
 WHERE post_id = 142;
