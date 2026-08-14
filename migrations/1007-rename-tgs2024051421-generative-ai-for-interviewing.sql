-- 1007-rename-tgs2024051421-generative-ai-for-interviewing.sql
--
-- Rename SG WSQ course TGS-2024051421
--   OLD: WSQ - Improve Hiring Decisions with GenAI Assisted Interview Questioning
--   NEW: WSQ - Generative AI for Interviewing
--
-- This is a RETITLE + content refresh, not a repurpose: the course still teaches
-- GenAI-assisted interviewing, so category placements, funding tags and the
-- SSG-registered learning outcomes (cms_block course_TGS-2024051421_learning_outcomes,
-- already byte-identical to the requested LO1-LO3) are deliberately left untouched.
-- SKU is unchanged so every SkillsFuture / SFEC / SFC / PSEA deep link keyed on the
-- course code stays valid.
--
-- Idempotent: every statement is guarded or converges on re-run.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024051421');

-- ---------------------------------------------------------------------------
-- Surface 1: name  (keep the "WSQ - " prefix; the storefront H1 wants it)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Generative AI for Interviewing'
 WHERE entity_id = @e AND attribute_id = 71;

-- ---------------------------------------------------------------------------
-- Surface 2: meta_title -> PLAIN title. No leading "WSQ", no brand suffix.
-- MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs and appends the brand
-- postfix at render time; the stored value baked in BOTH, yielding
-- "WSQ funded WSQ Improve ... | Tertiary Courses Singapore".
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
   SET value = 'Generative AI for Interviewing'
 WHERE entity_id = @e AND attribute_id = 82;

-- ---------------------------------------------------------------------------
-- Surface 9: meta_description (varchar table; feeds <meta description>,
-- og:description, twitter:description AND the JSON-LD description)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
   SET value = 'Use Generative AI across the interviewing process - plan structured interviews, generate role-specific questions, evaluate candidate responses and support fair, evidence-based hiring decisions. Enjoy up to 70% WSQ funding subsidy.'
 WHERE entity_id = @e AND attribute_id = 84;

-- ---------------------------------------------------------------------------
-- Surface 5: image / small_image / thumbnail LABELS + media gallery label.
-- These are ALT TEXT -> plain title, no "WSQ - " prefix (the cover itself
-- strips the prefix via CourseImage/Model/Cover.php::cleanTitle).
-- NOTE: the image/small_image/thumbnail VALUES (/w/s/wsq---improve-hiring-...jpg)
-- are filesystem paths, NOT display text -- renaming them would 404 the file.
-- Deliberately untouched. The R2 cover PNG still bakes the old title and must be
-- re-rendered from the admin (or by the live-apply cover step) after deploy.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
   SET value = 'Generative AI for Interviewing'
 WHERE entity_id = @e AND attribute_id IN (112, 113, 114);

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Generative AI for Interviewing'
 WHERE g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- Surface 4: short_description. This course predates the 885-891 block
-- extraction split, so its sdesc is INTRO PROSE ONLY (no <h2>Course Brochure</h2>
-- tail, no inline vendor/exam-voucher sections) -- verified by dumping the full
-- value. A full replace is therefore correct here; a LOCATE-guarded splice would
-- silently no-op.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   SET v.value = CONCAT(
     '<p>This course equips HR professionals, hiring managers, and business leaders with practical skills to use Generative AI throughout the interviewing process. Participants will learn how to define interview objectives, analyse job requirements, develop structured interview plans, and generate relevant behavioural, situational, competency-based, and technical questions for different roles and seniority levels.</p>\n',
     '<p>Learners will use Generative AI to tailor questions to job competencies, create consistent evaluation criteria, develop scoring rubrics, and generate appropriate follow-up questions based on candidate responses. The course also strengthens essential human interviewing skills, including active listening, probing, note-taking, response evaluation, and the delivery of constructive feedback.</p>\n',
     '<p>Participants will explore how Generative AI can assist in summarising interview notes, comparing candidates against defined job-related criteria, identifying information gaps, and preparing evidence-based hiring recommendations. Emphasis is placed on maintaining human oversight and ensuring that AI-generated outputs are accurate, relevant, and free from inappropriate assumptions.</p>\n',
     '<p>The course also addresses responsible interviewing practices, including fairness, inclusion, candidate privacy, data protection, bias awareness, and compliance with organisational hiring policies. By the end of the course, participants will be able to apply Generative AI to conduct more structured and consistent interviews, improve candidate evaluation, and support fair, informed, and defensible hiring decisions.</p>'
   )
 WHERE v.entity_id = @e AND a.attribute_code = 'short_description';

-- ---------------------------------------------------------------------------
-- description: the Course Outline. Rewritten to the 3 requested Topics.
-- Rebuilds BOTH the LSN_DATA JSON comment (consumed by the outline renderer)
-- and the visible <p> markup, and clears the U+FFFD replacement chars that the
-- old value carried in its topic headings.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   SET v.value = CONCAT(
     '<!-- LSN_DATA: [',
       '{"title":"Topic 1: Responsible Interview Planning and Preparation with Generative AI","subsecs":[]},',
       '{"title":"Topic 2: Creating Structured and Role-Specific Interview Questions with Generative AI","subsecs":[]},',
       '{"title":"Topic 3: Candidate Response Evaluation, Interview Feedback and Hiring Decisions","subsecs":[]}',
     '] -->\n',
     '<p><strong>Topic 1: Responsible Interview Planning and Preparation with Generative AI</strong></p>\n',
     '<p><strong>Topic 2: Creating Structured and Role-Specific Interview Questions with Generative AI</strong></p>\n',
     '<p><strong>Topic 3: Candidate Response Evaluation, Interview Feedback and Hiring Decisions</strong></p>'
   )
 WHERE v.entity_id = @e AND a.attribute_code = 'description';

-- ---------------------------------------------------------------------------
-- Surface 6: trainerprofile. Ray Teoh's bio para 2 embeds the OLD TITLE inside
-- <em>...</em>. Targeted REPLACE on the inner title text only, so the
-- surrounding &nbsp;/&ndash; entities and every other bio survive byte-identical.
-- The other 4 bios are already title-free (they say "In this course, ..."), and
-- their remaining "hiring"/"recruitment" wording is genuine subject matter, not
-- a leak. Single-line target, so the CRLF REPLACE() trap does not apply.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   SET v.value = REPLACE(
         v.value,
         '<em>Improve Hiring Decisions with GenAI Assisted Interview Questioning</em>',
         '<em>Generative AI for Interviewing</em>'
       )
 WHERE v.entity_id = @e AND a.attribute_code = 'trainerprofile';

-- ---------------------------------------------------------------------------
-- Surface 8: brochure CMS block title (the PDF path keys on the unchanged SKU,
-- so only the human-readable title moves).
-- ---------------------------------------------------------------------------
UPDATE cms_block
   SET title = 'Course Brochure - TGS-2024051421'
 WHERE identifier = 'course_TGS-2024051421_brochure';

-- ---------------------------------------------------------------------------
-- Surface 3: url_key + the 301 for the old bare slug.
--
-- The old bare slug is owned by the product's OWN is_system = 1 rewrite, so an
-- INSERT IGNORE 301 would silently no-op against the unique key on
-- (request_path, store_id). Convert that system row IN PLACE into the 301.
-- The URL Rewrites indexer auto-301s the ~20 category paths on refresh.
--
-- url_path is DELETED at every scope so the indexer regenerates it. See
-- feedback_rename_301_vs_system_rewrite_suffix_trap: on the LIVE reindex the
-- 301 row must be dropped BEFORE refreshProductRewrite() and re-inserted after,
-- or getUnusedPathByUrlKey mints a "-626" suffixed slug and the clean URL 404s.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-generative-ai-for-interviewing'
 WHERE entity_id = @e AND attribute_id = 97;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = 98;

-- Clear any previously minted "-626" suffixed collision rows (idempotency guard).
DELETE FROM core_url_rewrite
 WHERE is_system = 1
   AND id_path LIKE CONCAT('product/', @e, '%')
   AND request_path LIKE CONCAT('%-', @e, '.html');

-- Convert the product's own system rewrite on the OLD bare slug into a 301.
UPDATE core_url_rewrite
   SET target_path = 'wsq-generative-ai-for-interviewing.html',
       is_system   = 0,
       options     = 'RP'
 WHERE product_id   = @e
   AND request_path = 'wsq-improve-hiring-decisions-with-genai-assisted-interview-questioning.html'
   AND is_system    = 1;

-- Re-point the pre-existing alias 301s (old course names that already redirected
-- here) at the NEW slug, so they chain to a live page instead of a dead one.
-- Anchored on the FULL old filename to avoid sibling-family over-match.
UPDATE core_url_rewrite
   SET target_path = 'wsq-generative-ai-for-interviewing.html'
 WHERE store_id = 1
   AND is_system = 0
   AND target_path = 'wsq-improve-hiring-decisions-with-genai-assisted-interview-questioning.html';

-- Category-scoped aliases likewise.
UPDATE core_url_rewrite
   SET target_path = REPLACE(
         target_path,
         '/wsq-improve-hiring-decisions-with-genai-assisted-interview-questioning.html',
         '/wsq-generative-ai-for-interviewing.html'
       )
 WHERE store_id = 1
   AND is_system = 0
   AND target_path LIKE '%/wsq-improve-hiring-decisions-with-genai-assisted-interview-questioning.html';
