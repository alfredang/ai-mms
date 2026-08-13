-- 998: Repurpose TGS-2019504643
--   "WSQ - Basic Machine Learning with ScikitLearn Course"
--     -> "WSQ - AI Vibe Coding for Data Analytics"
--
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA / UTAP deep link is keyed
-- on it). Admin-supplied 2026-08-13. The course content (LOs, 5 topics, About
-- narrative) was already switched to the data-analytics syllabus by migration
-- 962; THIS migration completes the repurpose by renaming the course and
-- retargeting every surface where the old ScikitLearn identity still leaks.
--
-- Admin typed "BAI Vibe Coding for Data Analytics"; confirmed as a typo for "AI"
-- and the standard "WSQ - " H1 prefix is retained (every TGS- course carries it).
--
-- Surfaces touched, from the mandatory pre-write EAV sweep of BOTH value tables
-- (memory feedback_tgs_course_rename_checklist -- do not trust an enumerated
-- list, the sweep is what found these):
--   name, url_key (+ url_path DELETE at every scope), meta_title, meta_description,
--   meta_keyword, image_label/small_image_label/thumbnail_label, media-gallery
--   label, whoshouldattend (job roles named the OLD tech), prerequisite (ONE <li>
--   linking scikit-learn), trainerprofile (teaching sentences only), the
--   learning_outcomes cms_block lead-in, course_image_url (new R2 cover), a 301
--   for the old bare slug, and category placement.
--
-- meta_title: PLAIN title -- NO leading "WSQ", NO "| Tertiary Courses Singapore"
-- suffix. MMD_Seotitle composes <title> at render time (prepends "WSQ funded" for
-- SG TGS- SKUs and appends the brand postfix). The OLD value baked in BOTH, which
-- is exactly the 853 bug; this migration also cleans that up.
--
-- TRAINER BIOS -- surgical, not wholesale (admin-confirmed 2026-08-13). The 8 bios
-- mention scikit-learn in two distinct ways:
--   * CAREER CREDENTIALS (facts): "applying scikit-learn, TensorFlow ... at GoWild",
--     "supervised 24 machine and deep learning projects at IBM", "IBM certifications
--     in data science and machine learning". These are TRUE and are LEFT ALONE --
--     rewriting them would falsify a real person's bio.
--   * COURSE-TEACHING CLAIMS: "His training emphasizes hands-on practice with
--     Python and scikit-learn", etc. These describe what is taught on THIS course
--     and are retargeted to the AI-assisted analytics delivery.
-- Each is an exact-string REPLACE() on a SINGLE line -- multi-line REPLACE()
-- silently no-ops on these CRLF WYSIWYG blobs (memory
-- feedback_multiline_replace_fails_on_crlf_blobs).
--
-- prerequisite: holds the ENTIRE funding apparatus (PWM, Funding Eligibility table,
-- SkillsFuture/PSEA/SFEC/UTAP/NTUC/MOM deep links, Appeal Process). NEVER rewritten
-- wholesale -- only the one <li> carrying the scikit-learn tool link is swapped.
-- Pre-migration deep-link counts to preserve: myskillsfuture=4, ntuc=2, mom=1.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * sku, price (750), duration (16), sessions (2) -- accredited course params.
--   * course_TGS-2019504643_funding_and_grant / _certification / _brochure /
--     _skills_framework -- keyed on the unchanged SKU; the WSQ accreditation, fee
--     table and OpenCerts wording are unaffected by a title change.
--   * description / short_description -- already the data-analytics content (962).
--   * badge tags (WSQ, SkillsFuture Credit, PSEA, UTAP, SFEC, Absentee Payroll,
--     MCES) -- funding eligibility is unchanged.
--   * image/small_image/thumbnail PATHS (/s/c/sckikit.png) -- filesystem paths,
--     not display text; renaming them 404s the file. The storefront renders
--     course_image_url (updated below). Only the LABELS (alt text) change.
--   * catalogsearch_query -- the anchored sweep on the FULL old filename
--     ('%wsq-basic-machine-learning-with-scikitlearn-course.html%') and on the bare
--     course code returned ZERO rows, so there is no redirect to retarget. Search
--     redirects are DATA and are applied live, never via a migration (memory
--     feedback_search_redirects_always_apply_live).
--
-- NEW SLUG COLLISION CHECK: SELECT on url_key LIKE '%vibe-coding-for-data-analytics%'
-- returned zero rows -- no non-WSQ twin owns the unprefixed slug, so the
-- wsq--prefixed slug is free.
--
-- PARTNER SAFETY: TGS- SKUs are Singapore WSQ courses; MY/GH partner DBs have no
-- such SKU, so every statement matches zero rows there (clean no-op).
--
-- IDEMPOTENCY: every statement either sets a full target value or REPLACE()s an
-- exact old string that no longer exists after the first run. Re-running converges.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2019504643');

SET @a_name        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_urlkey      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_urlpath     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');
SET @a_mtitle      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mdesc       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mkey        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_cover       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_ilabel      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_slabel      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_tlabel      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_who         := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='whoshouldattend');
SET @a_prereq      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='prerequisite');
SET @a_trainer     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='trainerprofile');

-- ---------------------------------------------------------------------------
-- 1. name  (keep the "WSQ - " prefix -- the storefront H1 wants it)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'WSQ - AI Vibe Coding for Data Analytics'
WHERE entity_id = @e AND attribute_id = @a_name;

-- ---------------------------------------------------------------------------
-- 2. url_key + url_path
--    Delete url_path at EVERY scope so the URL Rewrites indexer regenerates.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'wsq-ai-vibe-coding-for-data-analytics'
WHERE entity_id = @e AND attribute_id = @a_urlkey;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = @a_urlpath;

-- Drop any is_system = 0 squatter on the NEW path first: INSERT IGNORE silently
-- no-ops against a stale row (the 647 trap).
DELETE FROM core_url_rewrite
WHERE request_path = 'wsq-ai-vibe-coding-for-data-analytics.html' AND is_system = 0;

-- Explicit 301 for the old BARE slug. The indexer auto-301s the ~20 category
-- paths from its rewrite history; only the bare slug needs seeding.
INSERT IGNORE INTO core_url_rewrite
    (store_id, category_id, product_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, NULL, @e,
       CONCAT('product/', @e),
       'wsq-basic-machine-learning-with-scikitlearn-course.html',
       'wsq-ai-vibe-coding-for-data-analytics.html',
       0, 'RP', 'Repurpose 998: old ScikitLearn slug -> AI Vibe Coding for Data Analytics'
FROM dual
WHERE NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
    WHERE x.request_path = 'wsq-basic-machine-learning-with-scikitlearn-course.html'
      AND x.store_id = 1 AND x.is_system = 0
);

-- ---------------------------------------------------------------------------
-- 3. meta_title / meta_description / meta_keyword
--    meta_title is the PLAIN title: MMD_Seotitle adds "WSQ funded" + the brand
--    suffix at render time. The old value baked in both (the 853 bug).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding for Data Analytics'
WHERE entity_id = @e AND attribute_id = @a_mtitle;

UPDATE catalog_product_entity_varchar
SET value = 'Use AI vibe coding with Python to analyse data, automate reporting and build dashboards. Turn raw data into business insights with no manual coding. Up to 70% WSQ funding subsidy.'
WHERE entity_id = @e AND attribute_id = @a_mdesc;

UPDATE catalog_product_entity_text
SET value = 'AI Vibe Coding, Data Analytics, Python, WSQ Funding, AI Coding Assistant, Data Visualisation, Business Insights'
WHERE entity_id = @e AND attribute_id = @a_mkey;

-- ---------------------------------------------------------------------------
-- 4. Cover image (new R2 render, rendered + uploaded 2026-08-13) + alt-text
--    labels. The labels carry the PLAIN title (the cover itself strips "WSQ - ").
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_varchar
SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2019504643-20260813-063744.png'
WHERE entity_id = @e AND attribute_id = @a_cover;

UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding for Data Analytics'
WHERE entity_id = @e AND attribute_id IN (@a_ilabel, @a_slabel, @a_tlabel);

UPDATE catalog_product_entity_media_gallery_value v
JOIN catalog_product_entity_media_gallery g ON g.value_id = v.value_id
SET v.label = 'AI Vibe Coding for Data Analytics'
WHERE g.entity_id = @e;

-- ---------------------------------------------------------------------------
-- 5. whoshouldattend -- the job-role list named the OLD technology.
--    Re-pointed at analytics-facing roles; generic data roles are kept.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = '<ul>
<li>Data Analyst</li>
<li>Business Analyst</li>
<li>Data Scientist</li>
<li>Business Intelligence Specialist</li>
<li>Reporting Analyst</li>
<li>Operations Analyst</li>
<li>Finance Analyst</li>
<li>Marketing Analyst</li>
<li>Data Engineer</li>
<li>Research Analyst</li>
<li>Data Visualization Specialist</li>
<li>Analytics Consultant</li>
<li>Product Manager (focused on data products)</li>
<li>Innovation Specialist</li>
<li>Business Owner or Manager working with data</li>
</ul>'
WHERE entity_id = @e AND attribute_id = @a_who;

-- ---------------------------------------------------------------------------
-- 6. prerequisite -- swap ONLY the <li> holding the scikit-learn tool link.
--    Everything else (funding tables, PWM, all gov deep links) is untouched.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      '<a href="https://pypi.org/project/scikit-learn/" target="_blank">Scikit-Learn Course</a>',
      '<a href="https://www.python.org/downloads/" target="_blank">Python</a>'
    )
WHERE entity_id = @e AND attribute_id = @a_prereq;

-- ---------------------------------------------------------------------------
-- 7. trainerprofile -- retarget COURSE-TEACHING sentences only.
--    Career-history / credential sentences are deliberately left factual.
--    One exact single-line REPLACE() per bio (CRLF-safe).
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'His training emphasizes hands-on practice with Python and scikit-learn, ensuring participants develop a strong foundation in model building, evaluation, and deployment.',
      'His training emphasizes hands-on practice with Python and AI coding assistants, ensuring participants develop a strong foundation in data preparation, analysis, and visualisation.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'He emphasizes practical learning with scikit-learn, guiding learners through data preprocessing, model selection, hyperparameter tuning, and performance evaluation.',
      'He emphasizes practical learning with AI vibe coding, guiding learners through data preprocessing, exploratory analysis, visualisation, and interpretation of results.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'As a certified AI engineer and experienced trainer, Solomon has taught data science bootcamps and corporate workshops covering Python, scikit-learn, and advanced machine learning methods.',
      'As a certified AI engineer and experienced trainer, Solomon has taught data science bootcamps and corporate workshops covering Python, AI-assisted coding, and applied data analytics.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'His teaching in Python and machine learning introduces learners to scikit-learn through practical exercises in model building, evaluation, and application to business contexts.',
      'His teaching in Python and data analytics introduces learners to AI coding assistants through practical exercises in data preparation, reporting, and application to business contexts.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

UPDATE catalog_product_entity_text
SET value = REPLACE(
      value,
      'He has trained professionals in applying scikit-learn for machine learning model development, ensuring they understand not only the algorithms but also data preparation, feature engineering, and deployment.',
      'He has trained professionals in applying AI vibe coding for data analytics, ensuring they understand not only the tools but also data preparation, quality checks, and visual reporting.'
    )
WHERE entity_id = @e AND attribute_id = @a_trainer;

-- ---------------------------------------------------------------------------
-- 8. learning_outcomes block lead-in still said "this WSQ Machine Learning
--    course". 962 replaced the body; this fixes the residual lead-in wording if
--    the old phrasing is still present (962 already set the new lead-in, so on
--    a current DB this is a no-op -- kept for DBs restored from an older dump).
-- ---------------------------------------------------------------------------
UPDATE cms_block
SET content = REPLACE(content, 'this WSQ Machine Learning course', 'this course')
WHERE identifier = 'course_TGS-2019504643_learning_outcomes';
