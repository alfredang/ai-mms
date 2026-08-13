-- 962: Content update for TGS-2019504643
--   "WSQ - Basic Machine Learning with ScikitLearn Course"
--
-- NOT a repurpose. The SKU, course name, url_key, price, duration, categories,
-- funding apparatus and every SkillsFuture/SFEC/SFC/PSEA deep link are all
-- keyed on an unchanged course identity. This migration rewrites THREE content
-- surfaces only, from admin-supplied copy (2026-08-13):
--
--   1. course_TGS-2019504643_learning_outcomes (cms_block) -- the five LOs are
--      restated without the trailing full stops and without the "WSQ Machine
--      Learning course" lead-in, matching the supplied wording exactly.
--   2. catalog_product_entity_text.description -- the five-topic Course Outline
--      replaces the old five-topic outline. Topic bodies (the <ul> subtopics)
--      are DROPPED because the supplied outline gives topic titles only.
--   3. catalog_product_entity_text.short_description -- the "What's This Course
--      About" narrative, replaced with the supplied five-paragraph text.
--
-- ADMIN-CONFIRMED VERBATIM (2026-08-13). Two deliberate content mismatches were
-- raised with the admin before writing and were confirmed to ship AS SUPPLIED:
--   * The About narrative describes AI vibe coding for DATA ANALYTICS
--     (spreadsheets, CSV/database imports, dashboards, business reporting,
--     introductory forecasting). It does not mention Scikit-Learn and does not
--     track the LO/topic list on the same page, which is classification /
--     regression / clustering / PCA. Shipped verbatim on admin instruction.
--   * Topic 1 keeps the "AI Vibe Coding" and "for Data Analytics" qualifiers
--     while Topics 2-5 are pure Scikit-Learn ML. Shipped verbatim on admin
--     instruction.
-- Recorded here so a future reader does not "fix" this back into alignment and
-- silently undo an explicit decision.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * sku / name / url_key / url_path -- course identity is unchanged, so there
--     is NO rename, NO 301 and no search-redirect retarget to do. The
--     course-url-change checklist does not apply.
--   * course_TGS-2019504643_funding_and_grant / _certification / _brochure /
--     _skills_framework -- all keyed on the unchanged SKU; the accredited
--     standard, fee table and OpenCerts wording are unaffected.
--   * meta_title / meta_description / meta_keyword -- still describe a basic
--     Scikit-Learn machine learning course, which the course still is.
--   * price / duration / sessions / whoshouldattend / prerequisite /
--     additional_note / assessment_methods / trainerprofile.
--   * image/small_image/thumbnail paths and the rendered cover PNG.
--   * All category placements.
--
-- MARKUP SHAPE: description keeps <h3 class="course-topic-h3"> topic headings,
-- the shape ~1,295 courses already use. The theme normalises the bullet/heading
-- look in CSS + JS shims (see memory feedback_what_youll_learn_card_markup_
-- normalization) -- do NOT add a data migration to restyle these.
--
-- IDEMPOTENCY: every statement sets the FULL target value (never a REPLACE()
-- over a fragment) and is guarded on the SKU / block identifier, so re-running
-- is a no-op. Full-value SET is also what makes this safe against the CRLF line
-- endings in these rows -- a multi-line REPLACE() would silently no-op on them
-- (memory feedback_multiline_replace_fails_on_crlf_blobs).
--
-- PARTNER SAFETY: TGS- SKUs are Singapore WSQ courses. MY/GH partner DBs have
-- no such SKU, so every statement below matches zero rows there and the
-- migration is a clean no-op on those servers.

-- ---------------------------------------------------------------------------
-- 1. Learning Outcomes card
-- ---------------------------------------------------------------------------
UPDATE cms_block
SET content = '<p>By the end of this course, learners will be able to:</p>\r\n<ul>\r\n<li>LO1 - understand and apply machine learning concepts</li>\r\n<li>LO2 - understand and apply classification methods</li>\r\n<li>LO3 - understand and apply regression methods</li>\r\n<li>LO4 - understand and apply clustering methods</li>\r\n<li>LO5 - understand and apply PCA methods</li>\r\n</ul>'
WHERE identifier = 'course_TGS-2019504643_learning_outcomes';

-- ---------------------------------------------------------------------------
-- 2. Course Outline -> description ("What You'll Learn" card)
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text v
JOIN catalog_product_entity e      ON e.entity_id = v.entity_id
JOIN eav_attribute a               ON a.attribute_id = v.attribute_id
                                  AND a.attribute_code = 'description'
SET v.value = '<h3 class="course-topic-h3">Topic 1: AI Vibe Coding and Machine Learning Fundamentals for Data Analytics</h3>\r\n<h3 class="course-topic-h3">Topic 2: Data Classification and Performance Evaluation</h3>\r\n<h3 class="course-topic-h3">Topic 3: Regression Analysis and Predictive Modelling</h3>\r\n<h3 class="course-topic-h3">Topic 4: Clustering and Customer or Data Segmentation</h3>\r\n<h3 class="course-topic-h3">Topic 5: Principal Component Analysis and Dimensionality Reduction</h3>'
WHERE e.sku = 'TGS-2019504643';

-- ---------------------------------------------------------------------------
-- 3. About This Course -> short_description ("What's This Course About" card)
--
-- NOTE: this course's short_description carries the narrative ONLY -- the
-- Learning Outcomes / Brochure / Certification / Skills Framework sections all
-- live in their own cms/blocks (verified: the live value contains no <h2>
-- section heading for view.phtml::$_extractSection to strip). Replacing the
-- whole value therefore cannot destroy a carded section.
-- ---------------------------------------------------------------------------
UPDATE catalog_product_entity_text v
JOIN catalog_product_entity e      ON e.entity_id = v.entity_id
JOIN eav_attribute a               ON a.attribute_id = v.attribute_id
                                  AND a.attribute_code = 'short_description'
SET v.value = '<p>This course equips participants with practical skills to use AI vibe coding and Python for data analytics. Learners will use natural-language instructions and AI coding assistants to generate, explain, test, debug, and refine Python code, making data analysis faster and more accessible without requiring them to write every line of code manually.</p>\r\n<p>Participants will learn how to import, clean, transform, and organise data from common sources such as spreadsheets, CSV files, databases, and business reports. They will apply exploratory data analysis techniques to identify patterns, trends, relationships, anomalies, and performance gaps within datasets.</p>\r\n<p>The course covers descriptive statistics, data aggregation, segmentation, correlation analysis, and effective data visualisation. Learners will use AI-assisted workflows to select suitable analytical methods, create charts and dashboards, interpret results, and communicate findings clearly to stakeholders. Introductory predictive techniques will also be explored to support forecasting and data-driven decision-making.</p>\r\n<p>Through hands-on business projects, participants will develop end-to-end analytics workflows, from defining analytical questions and preparing data to producing visual reports and actionable recommendations. Emphasis is placed on validating AI-generated code, maintaining data quality, protecting sensitive information, and avoiding misleading interpretations.</p>\r\n<p>By the end of the course, learners will be able to use AI vibe coding with Python to analyse datasets, automate repetitive analytical tasks, visualise findings, and transform raw data into meaningful business insights.</p>'
WHERE e.sku = 'TGS-2019504643';
