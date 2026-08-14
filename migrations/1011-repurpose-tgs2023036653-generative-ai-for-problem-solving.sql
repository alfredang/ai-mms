-- 1011: Rename/repurpose TGS-2023036653
--   "WSQ - Innovative Problem Solving with Generative AI (GenAI)"
--     ->  "WSQ - Generative AI for Problem Solving"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-14.
--
-- LIVE NON-WSQ TWIN -- the collision this rename turns on
-- ------------------------------------------------------
-- C1234 (entity 1234, status = 1) is ALREADY named EXACTLY "Generative AI for
-- Problem Solving" and owns the bare slug 'generative-ai-for-problem-solving'.
-- This is the settled WSQ/non-WSQ twin-pair case
-- ([[feedback_repurpose_target_name_may_already_exist_as_live_twin]], 937/956):
--   * the twin is NOT renamed and NOT touched;
--   * this course KEEPS its 'WSQ - ' prefix in `name` (the segment follows the
--     unchanged TGS- SKU), and
--   * takes the 'wsq-'-PREFIXED slug 'wsq-generative-ai-for-problem-solving',
--     which keeps the two pages' core_url_rewrite rows permanently apart.
-- Probed free before writing: 0 rows in core_url_rewrite on the wsq- path and
-- 0 rows in catalog_product_entity_varchar holding that url_key.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title
-- (also FIXES a pre-existing bug -- see below), meta_description, meta_keyword,
-- short_description, description (3 topics), image/small_image/thumbnail labels,
-- media-gallery label, and a 301 for the old bare slug.
--
-- Deliberately UNCHANGED (each verified against live data BEFORE writing, per
-- the checklist's "scan, don't enumerate" rule -- both EAV value tables were
-- swept for the old title AND for 'GenAI'/'Generative AI'):
--   * course_TGS-2023036653_learning_outcomes -- the live block ALREADY holds the
--     supplied LO1-LO3 byte-for-byte. These are the SSG-accredited outcomes
--     registered against the unchanged SKU; the new topics are delivered against
--     those same outcomes.
--   * course_TGS-2023036653_skills_framework -- "Problem Identification
--     RET-ACE-4006-1.1 TSC". The subject (problem solving) is unchanged by this
--     rename, so the accredited standard still holds.
--   * course_TGS-2023036653_certification / _funding_and_grant / _brochure --
--     keyed on the unchanged SKU.
--   * prerequisite -- probed: LOCATE() = 0 for the old title, 'GenAI' AND
--     'Generative AI'. No old-tool link to retarget. (It also carries the whole
--     funding apparatus, so it must never be rewritten wholesale.)
--   * trainerprofile -- HITS but NOT a leak. It never names the old title
--     (LOCATE('Innovative Problem Solving') = 0); its 'Generative AI'/'GenAI'
--     mentions sit in a course-teaching claim that reads "guiding learners to
--     apply Generative AI for creative problem-solving and business innovation"
--     -- still exactly accurate under the NEW title. Verify, then skip.
--   * whoshouldattend -- 15 roles (Operations Manager, Business Analyst, Process
--     Improvement Specialist, ...), all technology-neutral and all still correct.
--     This is the surface that leaks on a TOPIC pivot; this rename is not one.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--   * CATEGORIES -- all 13 still describe the course: 353 "Problem Solving",
--     252 "AI Courses", 379 "WSQ Generative AI Courses", 433 "Generative AI
--     Series", 200 "GenAI Content Creation", 68/300 (soft skills), 15/292 (WSQ
--     listings), 3 "All Courses" etc. The subject did not pivot and no
--     certification brand was dropped, so there is no exam-prep category to
--     shed -- no catalog_category_product / _index churn on this rename.
--   * catalogsearch_query -- probed: ZERO rows redirect at the old slug. The one
--     row matching the bare course code (query_id 57114, 'TGS-2023036653') has
--     redirect IS NULL and is left NULL: an empty redirect is not a TODO
--     ([[feedback_repurpose_target_name_may_already_exist_as_live_twin]]), and
--     filling it here risks pulling twin-intent traffic off C1234.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023036653' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_ilab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------- 1. Title
-- 'WSQ - ' prefix retained: the SKU is unchanged, so the segment is unchanged,
-- and the prefix is what keeps this page distinct from the live twin C1234.
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Generative AI for Problem Solving'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
-- The live value did BOTH ("WSQ Identifying and Solving Problems at the Workplace
-- | Tertiary Courses Singapore"), so this rename is also the fix for that
-- pre-existing double-prefix bug (checklist surface 2 / migration 853).
UPDATE catalog_product_entity_varchar
   SET value = 'Generative AI for Problem Solving'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to apply Generative AI to structured problem solving at work. Identify performance gaps and root causes, develop corrective action plans, evaluate and prioritise solutions, and measure their effectiveness. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'generative AI for problem solving, AI root cause analysis, performance gap analysis, corrective action plan, decision making with AI, AI problem solving techniques, solution evaluation criteria, implementation plan, continuous improvement, workplace problem solving course, WSQ problem solving course Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL. (Live rows exist at
-- store 0 AND store 1 here.)
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-generative-ai-for-problem-solving'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the NEW path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-generative-ai-for-problem-solving.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- NOTE: the old bare slug is held by this product's SYSTEM rewrite
-- (id_path 'product/1353', is_system = 1 -- confirmed row 2607139 at store 1), so
-- a plain INSERT IGNORE silently no-ops against the unique key on
-- (request_path, store_id). Convert that row in place into a permanent redirect;
-- the indexer then mints a fresh system row for the NEW slug.
-- See [[feedback_rename_301_vs_system_rewrite_suffix_trap]] for the live-reindex
-- ordering this implies (drop the 301 -> refreshProductRewrite -> re-add the 301),
-- without which refreshProductRewrite mints a '-1353'-suffixed slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-generative-ai-for-problem-solving.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-innovative-problem-solving-with-generative-ai-genai.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2023036653-rp-1011-', s.store_id),
       'wsq-innovative-problem-solving-with-generative-ai-genai.html',
       'wsq-generative-ai-for-problem-solving.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- Re-point the earlier renames' 301 chains (this course has been renamed twice
-- before: 'wsq-conflict-resolution-in-the-workplace-1353' and
-- 'wsq-identifying-and-solving-problems-at-the-workplace') at the new slug, so
-- those old URLs resolve in ONE hop instead of 301-chaining through a now-
-- redirecting path. Anchored on the FULL old filename so the live twin C1234's
-- rows (same 'problem-solving' stem, no 'wsq-' prefix) can never be caught --
-- see [[feedback_rename_sibling_family_courses_anchor_matches]].
UPDATE core_url_rewrite
   SET target_path = 'wsq-generative-ai-for-problem-solving.html'
 WHERE is_system = 0
   AND target_path = 'wsq-innovative-problem-solving-with-generative-ai-genai.html'
   AND request_path <> 'wsq-generative-ai-for-problem-solving.html'
   AND @e IS NOT NULL;

UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path,
                             '/wsq-innovative-problem-solving-with-generative-ai-genai.html',
                             '/wsq-generative-ai-for-problem-solving.html')
 WHERE is_system = 0
   AND target_path LIKE '%/wsq-innovative-problem-solving-with-generative-ai-genai.html'
   AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no 'WSQ - ' prefix): the cover itself strips the prefix
-- (CourseImage/Model/Cover.php::cleanTitle). The media-gallery row's own `label`
-- column is what the product page actually renders as alt= -- the three *_label
-- attrs alone are NOT enough, see
-- [[feedback_media_gallery_label_is_the_real_alt_text]].
UPDATE catalog_product_entity_varchar
   SET value = 'Generative AI for Problem Solving'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Generative AI for Problem Solving'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------ 5. Course Outline (description)
-- This course predates the LSN_DATA JSON shape -- its live markup is the older
-- '<h3 class="course-topic-h3">' + '<ul>' bullet form, which is preserved here.
-- The three supplied topic titles replace the old ones; the sub-bullets are the
-- existing accredited content re-pointed at Generative AI, matching LO1-LO3.
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: Identifying Performance Gaps and Root Causes with Generative AI</h3>
<ul>
<li>Criteria for identifying performance deficiency or cause of failure in organisational systems and processes</li>
<li>Types of analytical tools and techniques in terms of problem identification</li>
<li>Use Generative AI to examine the types of performance deficiency and their impact on organisation-related aspects</li>
<li>Identify the root causes of problems with team members using appropriate group facilitation techniques</li>
<li>Apply Generative AI to analyse complex information and uncover patterns from multiple perspectives</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Developing Corrective Plans and Evaluating Potential Solutions</h3>
<ul>
<li>Techniques used during problem solving and decision making processes</li>
<li>Types of decision making models for arriving at the preferred solution and their features</li>
<li>Rationale for the different components in a corrective action plan</li>
<li>Deduce relevant linkages and patterns to identify key implications on organisational systems and processes</li>
<li>Use Generative AI with root-cause analysis and creative thinking techniques to generate potential solutions</li>
<li>Shortlist and evaluate the most viable ideas using appropriate problem-solving and decision-making tools</li>
</ul>
<h3 class="course-topic-h3">Topic 3: Selecting, Implementing and Measuring the Effectiveness of Solutions</h3>
<ul>
<li>Evaluate and prioritise solutions against defined criteria such as feasibility, cost, risk, impact and resources</li>
<li>Determine a preferred solution and draw up implementation plans specifying responsibilities, timelines and performance measures</li>
<li>Techniques and factors affecting the effectiveness of an implemented solution and its implementation plan</li>
<li>Use Generative AI to support implementation planning, monitor results and recommend further improvements</li>
<li>Verify AI-generated information, protect confidential data, recognise bias and maintain human oversight</li>
</ul>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Full replace. Verified first (checklist surface 12): the live short_description
-- is prose ONLY (805 chars, two <p> paragraphs) -- no <h2>Course Brochure</h2>
-- tail and no ad-hoc inline certification-vendor sections -- so nothing is
-- silently destroyed. All five standard sections live in the
-- course_TGS-2023036653_* cms blocks.
UPDATE catalog_product_entity_text
   SET value = '<p>This course equips participants with practical skills to use Generative AI for structured problem-solving and informed decision-making in the workplace. Learners will identify performance gaps, define problems clearly, gather relevant information, and investigate the root causes of operational and organisational challenges.</p>
<p>Participants will apply Generative AI to analyse complex information, uncover patterns, examine issues from multiple perspectives, and generate potential solutions. They will use established analytical methods, root-cause analysis tools, creative thinking techniques, and collaborative approaches to develop well-supported responses to real-world problems.</p>
<p>The course also covers how to evaluate and prioritise proposed solutions using defined criteria such as feasibility, cost, risk, impact, resources, and alignment with organisational objectives. Learners will develop corrective action plans that specify responsibilities, timelines, expected outcomes, and performance measures.</p>
<p>Through practical activities, participants will use Generative AI to support implementation planning, monitor results, evaluate solution effectiveness, and recommend further improvements. Emphasis is placed on verifying AI-generated information, protecting confidential data, recognising potential bias, and maintaining human oversight.</p>
<p>By the end of the course, participants will be able to integrate Generative AI into a systematic problem-solving process&mdash;from problem identification and root-cause analysis to solution development, implementation, and continuous improvement.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;
