-- 1567: TGS-2024051421 -> "WSQ - Microsoft Copilot for HR Recruitment"
--
-- Converts the course from "Generative AI for Interviewing" to "Microsoft
-- Copilot for HR Recruitment" (admin request 2026-09-27). The SKU and the
-- accredited TSC (Interviewing RET-PMD-4003-1.1, cms_block
-- course_TGS-2024051421_skills_framework) are UNCHANGED, so every SkillsFuture /
-- SFEC / SFC / PSEA / UTAP deep link, the funding block, the certification
-- block and the brochure block stay valid and are not touched.
--
-- TOOL SWAP, not a subject change: the supplied LO1-LO3 are byte-equivalent to
-- the live course_TGS-2024051421_learning_outcomes block, so that block is NOT
-- touched. whoshouldattend (20 tool-neutral HR roles) is clean and not touched.
--
-- Pre-write probe (SG prod, entity 626) found the old topic on: name, url_key,
-- meta_*, short_description, description (LSN_DATA outline), the 3 alt labels +
-- gallery label, the course-teaching paragraph of all 5 trainer bios, the
-- prerequisite software line ("TBD"), cat 433, 30 search-term rows, blog posts
-- 144/145 (course links + course-name anchor text) and the cover PNG.
--
-- NON-WSQ TWIN: C169 (entity 169) is live at `generative-ai-for-interviewing.html`
-- and still teaches the OLD title. Every rewrite / search / blog predicate here
-- is anchored on the `wsq-` filename so none of the twin's rows are touched.
-- GenAI-worded search terms go to the twin, which still teaches exactly that.
--
-- SLUG: `wsq-microsoft-copilot-for-hr-recruitment` -- probe found no url_key,
-- name or core_url_rewrite row containing "copilot-for-hr".
--
-- CATEGORIES: 433 "Generative AI Series" is a title-branded series ("Generative
-- AI for X") and is dropped. 357 Microsoft Copilot Series, 378 AI for HR, 150 HR
-- Management and the GenAI listings that already hold M365 Copilot courses
-- (200, 379) are kept.
--
-- COVER: pre-rendered PNG on R2 with the title baked in. Re-rendered via
-- MMD_CourseImage_Model_Cover with the product's OWN badge set (WSQ, SkillsFuture
-- Credit, PSEA, SFEC, Absentee Payroll, MCES) and uploaded before this file:
--   course-covers/TGS-2024051421-20260926-162427.png  (163373 bytes, HTTP 200)
-- The superseded object stays on R2 so reverting is just repointing the URL.
--
-- POST-DEPLOY (code paths a migration cannot run, on the SG web container):
--   1. Mage::getSingleton('catalog/url')->refreshProductRewrite(626), then
--      catalog_product_flat reindex + cache flush -- the NEW slug 404s until
--      this runs, even though the old slug already 301s.
--   2. scripts/seo/generate-sitemaps.php so the sitemap lists the new slug.
--
-- SG production only; keyed by SKU so a partner site with no TGS-2024051421
-- no-ops. Idempotent: plain UPDATEs, INSERT IGNORE, self-extinguishing REPLACE()s.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024051421' LIMIT 1);
SET @et := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

-- ---------------------------------------------------------------------------
-- 1. Identity: name, url_key, url_path
-- ---------------------------------------------------------------------------
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'name' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Microsoft Copilot for HR Recruitment'
 WHERE attribute_id = @a_name AND entity_id = @e AND @e IS NOT NULL;

SET @a_url := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_key' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-microsoft-copilot-for-hr-recruitment'
 WHERE attribute_id = @a_url AND entity_id = @e AND @e IS NOT NULL;

-- url_path: DELETE at every scope (store 0 AND store 1 rows exist) so the URL
-- Rewrites indexer regenerates it
SET @a_upath := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_path' AND entity_type_id = @et);
DELETE FROM catalog_product_entity_varchar
 WHERE attribute_id = @a_upath AND entity_id = @e AND @e IS NOT NULL AND @a_upath IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. Meta
-- ---------------------------------------------------------------------------

-- meta_title: PLAIN title (MMD_Seotitle adds "WSQ funded" + brand at render time)
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_title' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'Microsoft Copilot for HR Recruitment'
 WHERE attribute_id = @a_mt AND entity_id = @e AND @e IS NOT NULL;

-- meta_description: varchar(255) -- this value is 216 chars
SET @a_md := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_description' AND entity_type_id = @et);
UPDATE catalog_product_entity_varchar
   SET value = 'Use Microsoft Copilot and AI agents for HR recruitment - screen candidates, generate structured interview questions and rubrics, and support fair, evidence-based hiring decisions. Enjoy up to 70% WSQ funding subsidy.'
 WHERE attribute_id = @a_md AND entity_id = @e AND @e IS NOT NULL;

SET @a_mk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'meta_keyword' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = 'Microsoft Copilot for HR, Copilot for recruitment, AI candidate screening, Copilot interview questions, structured interview rubrics, AI agents for recruitment, SharePoint candidate screening, responsible AI in hiring, WSQ HR course, WSQ funded Copilot course'
 WHERE attribute_id = @a_mk AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. Content: About narrative, Course Outline, software requirement
-- ---------------------------------------------------------------------------

-- short_description ("What's This Course About"): this course's sections were
-- extracted to cms_block rows, so it holds ONLY the intro copy -- full replace
-- with the supplied four paragraphs.
SET @a_sd := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'short_description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<p><strong>Microsoft Copilot for HR Recruitment</strong> equips participants with practical skills to apply Microsoft Copilot and AI agents to improve candidate screening, interview preparation, and recruitment decision-making. The course focuses on using AI responsibly to support HR professionals throughout key stages of the recruitment process while maintaining appropriate human oversight.</p>',
'\n<p>Participants will learn how to use Microsoft Copilot and AI agents to review candidate information stored in SharePoint, extract relevant qualifications, skills, experience, and competencies, and organise candidate information against defined job requirements. They will explore how to establish appropriate screening criteria and metrics, develop structured candidate evaluation frameworks, and use AI-generated insights to support consistent and evidence-based shortlisting decisions.</p>',
'\n<p>The course also covers the use of Microsoft Copilot to generate role-specific and candidate-appropriate interview questions based on job requirements and candidate profiles. Participants will learn to develop structured interview rubrics, competency-based assessment criteria, scoring guidelines, and evaluation methods to improve the consistency and quality of interviews.</p>',
'\n<p>Through practical exercises, participants will use Copilot to create simulated interview practice sessions, generate interview scenarios, evaluate responses against defined rubrics, and provide structured feedback. Emphasis is placed on responsible AI practices, data privacy, fairness, bias mitigation, human-in-the-loop review, and ensuring that final recruitment decisions remain appropriately governed by HR professionals.</p>')
 WHERE attribute_id = @a_sd AND entity_id = @e AND @e IS NOT NULL;

-- description (Course Outline): LSN_DATA JSON + rendered markup, in the shape
-- the admin outline editor writes. Three supplied topic titles, no subsecs.
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'description' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = CONCAT(
'<!-- LSN_DATA: [{"title":"Topic 1: Microsoft Copilot and AI Agents for Candidate Screening","subsecs":[]},{"title":"Topic 2: Microsoft Copilot for Candidate Interviewing and Evaluation","subsecs":[]},{"title":"Topic 3: Microsoft Copilot for Recruitment Automation and Decision Support","subsecs":[]}] -->',
'\n<p><strong>Topic 1: Microsoft Copilot and AI Agents for Candidate Screening</strong></p>',
'\n<p><strong>Topic 2: Microsoft Copilot for Candidate Interviewing and Evaluation</strong></p>',
'\n<p><strong>Topic 3: Microsoft Copilot for Recruitment Automation and Decision Support</strong></p>',
'\n')
 WHERE attribute_id = @a_desc AND entity_id = @e AND @e IS NOT NULL;

-- prerequisite ("Minimum Software/Hardware Requirement"): the software line read
-- "TBD". Swap only that fragment (same Microsoft Copilot link as the M365
-- Copilot sibling TGS-2024043856). The blob is also the whole funding
-- apparatus, so it is never rewritten wholesale. Self-extinguishing REPLACE.
SET @a_pre := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'prerequisite' AND entity_type_id = @et);
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<p><strong>Software:</strong></p><p>TBD</p>',
       '<p><strong>Software:</strong></p><ul><li><a href="https://adoption.microsoft.com/en-us/copilot/" target="_blank"><span style="text-decoration: underline;">Microsoft 365 Copilot</span></a> (with access to SharePoint)</li></ul>')
 WHERE attribute_id = @a_pre AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. Trainer bios: retarget ONLY the course-teaching paragraph of each of the
--    5 bios. Credential paragraphs are facts and stay. The blob is CRLF, so each
--    REPLACE targets single-line sentence text only.
-- ---------------------------------------------------------------------------
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'trainerprofile' AND entity_type_id = @et);

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Teck Hwa guides learners on how to leverage Generative AI tools to design smarter, more structured, and bias-aware interview processes. His sessions focus on developing AI-assisted questioning strategies, evaluating candidate responses using behavioral models, and improving decision consistency. Participants gain practical insights into integrating AI into recruitment workflows to make objective, fair, and evidence-based hiring decisions.',
       'In this course, Teck Hwa guides learners on how to use Microsoft Copilot and AI agents to design smarter, more structured, and bias-aware recruitment processes. His sessions focus on setting screening criteria for candidate shortlisting, building competency-based interview rubrics, and evaluating candidate responses consistently. Participants gain practical insights into integrating Copilot into recruitment workflows to make objective, fair, and evidence-based hiring decisions while HR professionals stay in control.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Teddy focuses on using Generative AI to transform traditional recruitment practices. His sessions demonstrate how AI-assisted systems can generate contextually relevant interview questions, assess candidate fit, and streamline talent evaluation. Learners benefit from his expertise in applying AI ethically and effectively to optimize HR operations while maintaining fairness, transparency, and organizational alignment.',
       'In this course, Teddy focuses on using Microsoft Copilot to transform traditional recruitment practices. His sessions demonstrate how Copilot and AI agents can review candidate information stored in SharePoint, generate role-specific interview questions, and streamline talent evaluation. Learners benefit from his expertise in applying AI ethically and effectively to optimize HR operations while maintaining fairness, transparency, data privacy, and organizational alignment.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Allen teaches participants how to integrate AI into the recruitment process to enhance interviewer consistency and quality. His sessions focus on the practical use of GenAI tools for generating role-specific interview questions, analyzing candidate communication patterns, and improving hiring objectivity. Learners gain actionable frameworks to design AI-supported interview workflows that balance efficiency, empathy, and human judgment.',
       'In this course, Allen teaches participants how to integrate Microsoft Copilot into the recruitment process to enhance interviewer consistency and quality. His sessions focus on the practical use of Copilot for generating role-specific interview questions, running simulated interview practice sessions, and improving hiring objectivity. Learners gain actionable frameworks to design Copilot-supported interview workflows that balance efficiency, empathy, and human judgment.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Riley explores how Generative AI can enhance interviewer performance and candidate experience. His sessions emphasize using AI-assisted systems to identify behavioral indicators, craft personalized interview questions, and reduce unconscious bias in evaluations.',
       'In this course, Riley explores how Microsoft Copilot can enhance interviewer performance and candidate experience. His sessions emphasize using Copilot to identify behavioral indicators, craft candidate-appropriate interview questions and structured feedback, and reduce unconscious bias in evaluations.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In <em>Generative AI for Interviewing</em>, Ray empowers HR professionals and business leaders to leverage generative AI for smarter and fairer recruitment. He guides participants through AI-assisted question generation, candidate profiling, and bias mitigation techniques to enhance interview quality and predictive hiring outcomes.',
       'In <em>Microsoft Copilot for HR Recruitment</em>, Ray empowers HR professionals and business leaders to leverage Microsoft Copilot and AI agents for smarter and fairer recruitment. He guides participants through Copilot-assisted candidate screening, interview question generation, and bias mitigation techniques to enhance interview quality and hiring outcomes.')
 WHERE attribute_id = @a_tp AND entity_id = @e AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. Cover image + alt text
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar v
   JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = @et
    SET v.value = 'Microsoft Copilot for HR Recruitment'
  WHERE v.entity_id = @e AND @e IS NOT NULL
    AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label');

-- media gallery label = the real alt text (the stored file PATH is left alone)
UPDATE catalog_product_entity_media_gallery_value gv
   JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
    SET gv.label = 'Microsoft Copilot for HR Recruitment'
  WHERE g.entity_id = @e AND @e IS NOT NULL;

SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'course_image_url' AND entity_type_id = @et);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @et, @a_ciu, 0, @e,
       'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2024051421-20260926-162427.png'
  WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id <> 0
   AND @e IS NOT NULL AND @a_ciu IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6. Categories: drop the title-branded "Generative AI Series" (433)
-- ---------------------------------------------------------------------------
DELETE FROM catalog_category_product
 WHERE product_id = @e AND @e IS NOT NULL AND category_id = 433;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND @e IS NOT NULL AND category_id = 433;

-- ---------------------------------------------------------------------------
-- 7. URL rewrites: 301 the old slug, flatten the chain history
-- ---------------------------------------------------------------------------
SET @sid := (SELECT store_id FROM core_store WHERE store_id > 0 ORDER BY store_id LIMIT 1);

-- The old bare slug is held by the canonical is_system=1 row; INSERT IGNORE
-- would no-op against it, so DELETE it first. refreshProductRewrite re-mints
-- the canonical row at the NEW slug post-deploy.
DELETE FROM core_url_rewrite
 WHERE product_id = @e AND is_system = 1
   AND request_path = 'wsq-generative-ai-for-interviewing.html'
   AND @e IS NOT NULL;

DELETE FROM core_url_rewrite
 WHERE request_path = 'wsq-microsoft-copilot-for-hr-recruitment.html'
   AND is_system = 0;

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT @sid, CONCAT('tgs2024051421-copilot-hr-bare-', @e),
       'wsq-generative-ai-for-interviewing.html',
       'wsq-microsoft-copilot-for-hr-recruitment.html',
       0, 'RP', '1567: TGS-2024051421 converted to Microsoft Copilot for HR Recruitment'
 WHERE @e IS NOT NULL AND @sid IS NOT NULL;

-- Flatten every PRE-EXISTING 301 that lands on the old WSQ filename (bare or
-- category-prefixed) straight to the new BARE slug: one hop, and no target
-- under cat 433, which this migration drops. Anchored on the `wsq-` filename so
-- the twin C169's `generative-ai-for-interviewing.html` rows never match.
UPDATE core_url_rewrite
   SET target_path = 'wsq-microsoft-copilot-for-hr-recruitment.html'
 WHERE is_system = 0
   AND (target_path = 'wsq-generative-ai-for-interviewing.html'
        OR target_path LIKE '%/wsq-generative-ai-for-interviewing.html')
   AND id_path NOT LIKE 'tgs2024051421-copilot-hr-%';

-- ---------------------------------------------------------------------------
-- 8. Search-term redirects (SG data; partner sites have no matching rows)
-- ---------------------------------------------------------------------------

-- GenAI-worded intent -> the live non-WSQ twin C169, which still teaches it.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/generative-ai-for-interviewing.html'
 WHERE redirect LIKE '%/wsq-generative-ai-for-interviewing.html'
   AND query_text IN ('Generative AI for Interviewing', 'genai interviewing',
                      'GenAI Interview', 'genai hiring');

-- Everything else (course code, interview / hiring terms, the earlier
-- "Improve Hiring Decisions ..." WSQ titles of this SKU) follows the course.
UPDATE catalogsearch_query
   SET redirect = REPLACE(redirect,
                          'wsq-generative-ai-for-interviewing.html',
                          'wsq-microsoft-copilot-for-hr-recruitment.html')
 WHERE redirect LIKE '%/wsq-generative-ai-for-interviewing.html';

-- "recruitment" had no redirect; this is now the recruitment course.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-microsoft-copilot-for-hr-recruitment.html'
 WHERE query_text = 'recruitment' AND (redirect IS NULL OR redirect = '')
   AND @e IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 9. Blog posts linking the course (144 Agentic AI for HR, 145 the Copilot
--    interviewing post): retarget the course links and the course-name anchor
--    text in the body. Post titles, slugs and metas are the posts' own
--    headlines and stay. Anchored on the `wsq-` link, so C169 is untouched.
-- ---------------------------------------------------------------------------
UPDATE mmd_blog_post
   SET content = REPLACE(REPLACE(REPLACE(content,
         'wsq-generative-ai-for-interviewing.html', 'wsq-microsoft-copilot-for-hr-recruitment.html'),
         'WSQ &ndash; Generative AI for Interviewing', 'WSQ &ndash; Microsoft Copilot for HR Recruitment'),
         'WSQ Generative AI for Interviewing', 'WSQ Microsoft Copilot for HR Recruitment')
 WHERE content LIKE '%/wsq-generative-ai-for-interviewing.html%'
   AND @e IS NOT NULL;
