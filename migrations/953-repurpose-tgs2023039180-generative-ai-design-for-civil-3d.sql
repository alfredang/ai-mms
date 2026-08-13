-- 953: Repurpose TGS-2023039180
--   "WSQ - Autodesk Certified Professional (ACP) for Civil 3D Infrastructure Design"
--     -> "WSQ - Generative AI Design for Civil 3D"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-13: pivot from the Autodesk ACP certification
-- exam-prep track to generative-AI-assisted civil design, modelling, analysis and
-- documentation workflows.
--
-- Sibling of 951 (TGS-2024051414) and 950 (TGS-2024052076) -- same shape.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title,
-- meta_description, meta_keyword, short_description, description (LSN_DATA JSON
-- kept in sync with the visible markup), trainerprofile (the two teaching
-- paragraphs that name the retired ACP certification), image/small_image/thumbnail
-- labels, media-gallery label, 301 for the old bare slug, and category placement
-- (add AI Courses 252; drop the two Autodesk exam-prep listings 216/222),
-- mirrored into catalog_category_product_index.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2023039180_learning_outcomes -- the supplied LO1-LO4 are
--     BYTE-EQUIVALENT to the live block (differing only by &nbsp; entities); they
--     are the SSG-accredited outcomes registered against the unchanged SKU, so
--     the new topics are delivered AGAINST those same outcomes. The What You'll
--     Learn card legitimately keeps naming Civil 3D -- that is not a leak.
--   * course_TGS-2023039180_skills_framework -- BEV-TDR-4005-1.1-1 Technical
--     Drawing under the Built Environment Skills Framework still describes the
--     course (the deliverable is still civil design documentation).
--   * course_TGS-2023039180_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; the fee table and OpenCerts wording are unaffected.
--     (Funding is tag-driven for TGS- since 891 -- the block is orphaned data.)
--   * whoshouldattend -- 15 generic civil/infrastructure roles (Civil Engineer,
--     Surveyor, Draftsperson...), none Autodesk- or ACP-specific; every one
--     still fits a generative-AI-for-civil-design course.
--   * prerequisite / additional_note / venue -- funding apparatus and logistics.
--     (prerequisite matched the leak grep only on the WSQ funding boilerplate's
--     own course-title mention -- see note at section 8.)
--   * Badge tags (WSQ, MCES, SFEC, UTAP, PSEA, SkillsFuture Credit, Absentee
--     Payroll) -- funding entitlement follows the unchanged SKU.
--   * Categories 3/15/53/69/71/72/182/292/293/301/312/345/366/398 -- broad
--     parents and subject listings (Software Training, Technical Drawing,
--     Autodesk, Autodesk Civil 3D, WSQ Funded...) that still describe the NEW
--     content: the course is still Civil 3D software training. Only the two
--     near-pure CERTIFICATION EXAM PREP children are dropped.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023039180' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_tprof  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_ilab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------- 1. Title
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Generative AI Design for Civil 3D'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
-- (The live value baked in BOTH "WSQ" and "| Tertiary Courses Singapore"; the
-- repurpose is the moment to fix that, per migration 933.)
UPDATE catalog_product_entity_varchar
   SET value = 'Generative AI Design for Civil 3D'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to apply generative AI across Civil 3D design, modelling, analysis and documentation. Covers terrain and surface modelling, site layouts, alignments, profiles, corridors, grading, drainage and infrastructure planning.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'generative AI Civil 3D, AI civil engineering design, AI terrain and surface modelling, AI corridor design, AI grading and drainage, AI alignments and profiles, AI infrastructure planning, AI quantity takeoff, AI design validation, civil design automation, WSQ Civil 3D course Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- New slug verified collision-free: the three sibling Civil 3D courses hold
-- autodesk-civil-3d-training (C994),
-- wsq-autocad-civil-3d-for-infrastructure-design (TGS-2021005539) and
-- civil-3d-for-infrastructure-design-autodesk-certified-professional-acp-cert-prep
-- (C1213). None collides with wsq-generative-ai-design-for-civil-3d.
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL (this product has store-0
-- AND store-1 url_path rows).
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-generative-ai-design-for-civil-3d'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the new path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-generative-ai-design-for-civil-3d.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- NOTE: the old bare slug is held by this product's SYSTEM rewrite
-- (id_path 'product/1449', is_system = 1, store 1), so a plain INSERT IGNORE
-- silently no-ops against the unique key on (request_path, store_id). Convert
-- that row in place into a permanent redirect instead; the indexer then mints a
-- fresh system row for the NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-generative-ai-design-for-civil-3d.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-autodesk-certified-professional-acp-for-civil-3d-infrastructure-design.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2023039180-rp-953-', s.store_id),
       'wsq-autodesk-certified-professional-acp-for-civil-3d-infrastructure-design.html',
       'wsq-generative-ai-design-for-civil-3d.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'Generative AI Design for Civil 3D'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Generative AI Design for Civil 3D'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------ 5. Topics Covered (description + JSON)
-- The visible <p><strong>Topic N</strong></p> markup and the LSN_DATA JSON
-- comment must stay in sync. The old outline was 10 topics with ~120 ACP exam
-- subsections; the supplied outline is FOUR topic-level entries (no subsecs),
-- matching LO1-LO4 one-for-one. The trailing "Written Assessment (SAQ)" line is
-- preserved -- it is the WSQ assessment marker, not outline content.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: AI-Assisted Civil 3D Model Interpretation and Structural Analysis","subsecs":[]},{"title":"Topic 2: Generative AI for Site Surveying, Soil Analysis and Foundation Design","subsecs":[]},{"title":"Topic 3: AI-Assisted Concrete and Steel Structure Design Validation","subsecs":[]},{"title":"Topic 4: AI for Design Maintainability and Sustainable Civil Engineering","subsecs":[]}] -->
<p><strong>Topic 1: AI-Assisted Civil 3D Model Interpretation and Structural Analysis</strong></p>
<p><strong>Topic 2: Generative AI for Site Surveying, Soil Analysis and Foundation Design</strong></p>
<p><strong>Topic 3: AI-Assisted Concrete and Steel Structure Design Validation</strong></p>
<p><strong>Topic 4: AI for Design Maintainability and Sustainable Civil Engineering</strong></p>

<p><em>Written Assessment (SAQ)</em></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Full replace is correct here: this course's short_description has NO
-- <h2>Course Brochure</h2> tail (post-885 block model), so there is nothing to
-- splice. The three retired sections it DID hold inline -- "Exam Voucher",
-- "Autodesk ATC" and "Certification Exam at Pearson Vue", including the deep
-- link to the ACP exam-voucher product -- are dropped deliberately: the course
-- no longer prepares learners for the Autodesk ACP exam, so advertising the
-- voucher under the new title would misrepresent it.
UPDATE catalog_product_entity_text
   SET value = '<p>Generative AI Design for Civil 3D equips participants with practical skills to apply generative AI across civil engineering design, modelling, analysis, and documentation workflows. Participants will learn to use natural-language prompts, project specifications, survey information, and design requirements to generate concepts, automate repetitive tasks, and support informed design decisions.</p>
<p>The course covers key civil design processes, including terrain and surface modelling, site layouts, alignments, profiles, corridors, grading, drainage, and infrastructure planning. Learners will explore how generative AI can assist in interpreting project requirements, generating design alternatives, identifying potential conflicts, validating models, and recommending improvements based on engineering constraints.</p>
<p>Through hands-on projects, participants will develop and refine civil 3D models, produce plans and technical documentation, calculate quantities, and prepare design outputs for review and collaboration. Emphasis is placed on verifying AI-generated results for accuracy, safety, compliance, and alignment with project specifications. By the end of the course, learners will be able to combine generative AI with established civil design practices to improve productivity, enhance design quality, and deliver efficient, well-documented infrastructure solutions.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------------- 7. Trainer bios
-- Two bios, each two paragraphs: para 1 = career CREDENTIALS -- FACTS (real
-- AutoCAD/Civil 3D/Revit expertise, BCA Academy lectureship, Autodesk Revit
-- Certified Professional), left untouched. Para 2 is a course-teaching claim
-- scoped to the retired ACP certification ("exam readiness", "succeed as
-- Autodesk Certified Professionals", "achieve ACP certification") -- both are
-- retargeted at the generative-AI workflow. Their genuine Civil 3D subject
-- expertise is retained, since the course still teaches Civil 3D.
-- Single-line REPLACE() on the full paragraph string (a multi-line pattern
-- no-ops against the WYSIWYG blob's CRLF line endings).
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In her Civil 3D training, Jyoti emphasizes guiding learners through infrastructure-specific design workflows, including terrain modeling, alignments, corridors, grading, and pipe networks. She integrates ACP-aligned practice with real-world project scenarios to ensure participants gain both the technical expertise and exam readiness to succeed as Autodesk Certified Professionals in Civil 3D Infrastructure Design.',
       'In this course, Jyoti emphasizes guiding learners through AI-assisted infrastructure design workflows, including terrain modeling, alignments, corridors, grading, and pipe networks. She integrates generative AI practice with real-world project scenarios to ensure participants gain both the technical expertise and the judgement to validate AI-generated design outputs in Civil 3D.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In his Civil 3D Infrastructure Design courses, Bernard focuses on precision and practical application. He teaches learners to create and manage civil engineering projects in Civil 3D, covering surfaces, alignments, profiles, cross-sections, and quantity takeoffs. His structured approach ensures participants not only achieve ACP certification but also gain the confidence to apply Civil 3D effectively in infrastructure and land development projects.',
       'In this course, Bernard focuses on precision and practical application. He teaches learners to create and manage civil engineering projects in Civil 3D with generative AI support, covering surfaces, alignments, profiles, cross-sections, and quantity takeoffs. His structured approach ensures participants gain the confidence to apply AI-assisted Civil 3D workflows effectively in infrastructure and land development projects.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 8. Category placement
-- The repurpose changes the PURPOSE: the course no longer prepares learners for
-- the Autodesk ACP exam, so drop the two near-pure Autodesk-certification
-- exam-prep listings (same call as migrations 936 / 951):
--   216 "Autodesk Certification Exam Prep" -- 15/15 members are ACP/ACU titles
--   222 "Autodesk Certification Exam Prep" -- duplicate listing, same 15 members
-- and join 252 "AI Courses", the master listing every AI course belongs to.
-- KEPT: 71 "Autodesk" and 312 "Autodesk Civil 3D" -- subject listings, still
-- accurate (the course still teaches Civil 3D); 182 "Certification Exam Prep"
-- -- the broad mixed parent, and the course still carries a WSQ Statement of
-- Achievement. Both sides mirrored into catalog_category_product_index or the
-- storefront listings never change.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (216, 222) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (216, 222) AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 252, @e, COALESCE((SELECT MAX(position) FROM catalog_category_product WHERE category_id = 252), 0) + 1
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 252);

INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 252, @e, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  CROSS JOIN core_store s
 WHERE cp.category_id = 252 AND cp.product_id = @e AND s.store_id > 0 AND @e IS NOT NULL;
