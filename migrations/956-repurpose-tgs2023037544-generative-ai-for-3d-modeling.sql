-- 956: Repurpose TGS-2023037544
--   "WSQ - Autodesk Certified Professional (ACP) for Inventor Mechanical Design"
--     -> "WSQ - Generative AI for 3D Modeling"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-13: pivot from the Autodesk ACP Inventor
-- certification exam-prep track to generative-AI-assisted 3D modelling.
--
-- Sibling of 953 (TGS-2023039180, the Civil 3D ACP -> generative-AI repurpose)
-- and 950/951 -- same shape, same Autodesk-exam-prep origin.
--
-- THE NON-WSQ TWIN (checklist surface: twin is a live third party).
--   C162 is a LIVE non-WSQ course ALREADY named exactly "Generative AI for 3D
--   Modeling" (1-day, text-to-3D/image-to-3D into Blender) and it OWNS the bare
--   slug `generative-ai-for-3d-modeling`. So:
--     * `name` keeps the "WSQ - " prefix (segment unchanged, SKU unchanged) --
--       the two courses coexist as the standard WSQ/non-WSQ twin pair, exactly
--       like TGS-2026064472 / C428 (migration 937).
--     * url_key takes the `wsq-` prefix -> `wsq-generative-ai-for-3d-modeling`,
--       verified collision-free (0 rows in catalog_product_entity_varchar.url_key
--       and 0 in core_url_rewrite.request_path). The prefix keeps the two pages'
--       rewrites permanently apart.
--     * NO catalogsearch_query retarget is performed -- see section 9.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title,
-- meta_description, meta_keyword, short_description, description, trainerprofile
-- (the three teaching paragraphs that name the retired ACP certification),
-- image/small_image/thumbnail labels, media-gallery label, the learning_outcomes
-- cms_block, 301 for the old bare slug, and category placement (add AI Courses
-- 252; drop the two Autodesk exam-prep listings 216/222 and Autodesk Inventor
-- 213), mirrored into catalog_category_product_index.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2023037544_skills_framework -- BEV-TDR-4005-1.1-1 Technical
--     Drawing under the Built Environment Skills Framework. The accredited
--     mapping follows the unchanged SKU; the deliverable is still 3D modelling
--     and technical documentation.
--   * course_TGS-2023037544_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; fee table and OpenCerts wording unaffected.
--     (Funding is tag-driven for TGS- since 891 -- the block is orphaned data.)
--   * whoshouldattend -- 15 generic design/engineering roles (Product Designer,
--     3D-adjacent CAD Technician, Industrial Designer, Prototype Developer...),
--     none Autodesk- or ACP-specific; every one still fits a generative-AI 3D
--     modelling course. NOT a leak -- verified role by role.
--   * prerequisite -- holds the entire funding apparatus (PWM, eligibility
--     table, SkillsFuture/PSEA/SFEC/UTAP deep links, Appeal Process). Its only
--     Autodesk hit is one "Minimum Software/Hardware Requirement" <li> linking
--     autodesk.com/products/inventor. That single <li> IS retargeted below
--     (section 8) with a surgical single-line REPLACE(); the funding apparatus
--     is never rewritten wholesale.
--   * additional_note / venue -- laptop logistics, tool-agnostic.
--   * Badge tags (WSQ, MCES, SFEC, UTAP, PSEA, SkillsFuture Credit, Absentee
--     Payroll) -- funding entitlement follows the unchanged SKU.
--   * Categories 3/15/53/69/71/72/182/292/293/301/345/366/398 -- broad parents
--     and subject listings (All Courses, Software Training, Media & Design,
--     Technical Drawing, WSQ Funded...) that still describe the NEW content.
--     Only the near-pure CERTIFICATION EXAM PREP children and the tool-specific
--     "Autodesk Inventor" listing are dropped.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037544' LIMIT 1);

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlp   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_tprof  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');
SET @a_prereq := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');
SET @a_ilab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_slab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_tlab   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');

-- ------------------------------------------------------------- 1. Title
-- "WSQ - " prefix retained: the storefront H1 wants it, and it is what keeps
-- this page distinguishable from the live non-WSQ twin C162 of the same name.
UPDATE catalog_product_entity_varchar
   SET value = 'WSQ - Generative AI for 3D Modeling'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
-- The live value baked in BOTH ("WSQ Autodesk Inventor ... | Tertiary Courses
-- Singapore"); the repurpose is the moment to fix that, per migrations 933/953.
UPDATE catalog_product_entity_varchar
   SET value = 'Generative AI for 3D Modeling'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to create, refine and optimise 3D models with AI-assisted design workflows. Covers text and image to 3D concepts, geometry and topology, textures and materials, model validation and production-ready export.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'generative AI 3D modeling, AI 3D model generation, text to 3D, image to 3D, AI textures and materials, 3D topology and geometry, AI model validation, polygon optimization, AI product visualization, 3D asset production workflow, WSQ 3D modeling course Singapore'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- `wsq-` prefixed BECAUSE the live non-WSQ twin C162 owns the bare slug
-- `generative-ai-for-3d-modeling` (see header). Verified collision-free.
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL (this product has store-0
-- AND store-1 url_path rows).
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-generative-ai-for-3d-modeling'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the new path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-generative-ai-for-3d-modeling.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- The old bare slug is held by this product's SYSTEM rewrite (id_path
-- 'product/1451', is_system = 1, store 1), so a plain INSERT IGNORE silently
-- no-ops against the unique key on (request_path, store_id). Convert that row in
-- place into a permanent redirect instead; the indexer then mints a fresh system
-- row for the NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-generative-ai-for-3d-modeling.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-autodesk-certified-professional-acp-for-inventor-mechanical-design.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2023037544-rp-956-', s.store_id),
       'wsq-autodesk-certified-professional-acp-for-inventor-mechanical-design.html',
       'wsq-generative-ai-for-3d-modeling.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'Generative AI for 3D Modeling'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'Generative AI for 3D Modeling'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------------ 5. Learning Outcomes block
-- The supplied outcomes are the LIVE SSG-accredited LO1-LO3 with the tool name
-- ("using Autodesk Inventor") dropped -- the accredited outcomes are registered
-- against the UNCHANGED SKU, so the new topics are delivered AGAINST those same
-- outcomes; only the retired tool reference goes. The block DOES already exist
-- (block_id 1948), but guard the INSERT anyway per surface 6b -- a bare UPDATE
-- silently no-ops on a course whose block was never created.
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2023037544 - Learning Outcomes',
       'course_TGS-2023037544_learning_outcomes',
       '', NOW(), NOW(), 1
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1 FROM cms_block WHERE identifier = 'course_TGS-2023037544_learning_outcomes') x);

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block WHERE identifier = 'course_TGS-2023037544_learning_outcomes';

UPDATE cms_block
   SET content = '<p>By end of the course, learners should be able to:</p>
<ul>
<li>LO1: Devise metrics for mechanical drawings and formulate solutions.</li>
<li>LO2:&nbsp;Analyze mechanical drawings for accuracy and design solutions.</li>
<li>LO3:&nbsp;Review mechanical drawings for organizational strategies and ensure conformity to standards.</li>
</ul>',
       update_time = NOW()
 WHERE identifier = 'course_TGS-2023037544_learning_outcomes';

-- ------------------------------------ 6. Topics Covered (description)
-- The old outline was 7 Autodesk-ACP topics with ~30 Inventor-specific
-- subsections. The supplied outline is THREE topic-level entries. Kept in the
-- live field's own shape: <h3 class="course-topic-h3"> headings, which is what
-- this product uses (it has NO <!-- LSN_DATA --> JSON comment, so there is no
-- JSON to keep in sync -- verified against the live value before writing).
UPDATE catalog_product_entity_text
   SET value = '<h3 class="course-topic-h3">Topic 1: Generative AI for 3D Design Concepts and Modeling</h3>
<h3 class="course-topic-h3">Topic 2: AI-Assisted 3D Model Analysis, Validation and Refinement</h3>
<h3 class="course-topic-h3">Topic 3: 3D Model Optimization, Standards and Production Workflows</h3>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 7. About This Course (sdesc)
-- Full replace is correct here: this course's short_description has NO
-- <h2>Course Brochure</h2> tail (post-885 block model), so there is nothing to
-- splice. The three retired sections it DID hold inline -- "Exam Voucher",
-- "Autodesk ATC" and "Certification Exam at Pearson Vue", including the deep
-- link to the ACP exam-voucher product -- are dropped deliberately: the course
-- no longer prepares learners for the Autodesk ACP exam, so advertising the
-- voucher under the new title would misrepresent it.
UPDATE catalog_product_entity_text
   SET value = '<p>Generative AI for 3D Modeling equips participants with practical skills to create, refine, and optimize 3D models using AI-assisted design workflows. Participants will learn how generative AI can translate text descriptions, reference images, sketches, and design requirements into 3D concepts, model variations, textures, and production-ready assets.</p>
<p>The course covers essential 3D modeling principles, including geometry, topology, materials, lighting, scale, and model organization. Learners will apply effective prompting techniques to generate design concepts, refine shapes, compare alternatives, automate repetitive tasks, and improve the quality and consistency of 3D assets.</p>
<p>Through hands-on projects, participants will create 3D models for product visualization, animation, games, architecture, marketing, and other creative applications. They will also learn to validate AI-generated models, correct geometry and topology issues, optimize polygon counts, apply textures and materials, and prepare assets for rendering, animation, or export. By the end of the course, learners will be able to combine generative AI with traditional 3D modeling techniques to accelerate ideation, improve productivity, and produce high-quality 3D designs aligned with project requirements.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------------- 8. Trainer bios
-- Three bios, each two paragraphs: para 1 = career CREDENTIALS -- FACTS (real
-- AutoCAD/Revit/Fusion 360/3ds Max/Blender expertise, BCA Academy lectureship,
-- Autodesk Revit Certified Professional). Left untouched: rewriting a career
-- history would falsify a bio. Para 2 in each is a course-teaching claim scoped
-- to the retired ACP certification ("exam readiness", "achieve Autodesk
-- certification", "ACP exam competence", "preparing for ACP certification") --
-- all three are retargeted at the generative-AI 3D workflow.
-- Single-line REPLACE() on the full paragraph string (a multi-line pattern
-- no-ops against the WYSIWYG blob's CRLF line endings).
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In her Inventor Mechanical Design courses, Jyoti focuses on modeling, assemblies, and technical documentation. She guides learners step by step through ACP-aligned competencies, ensuring they build both technical proficiency and exam readiness to achieve Autodesk certification.',
       'In this course, Jyoti focuses on AI-assisted 3D modeling, model refinement, and technical documentation. She guides learners step by step from prompt to production-ready asset, ensuring they build both technical proficiency and the judgement to validate AI-generated geometry against design requirements.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In his Inventor Mechanical Design training, Bernard emphasizes precision, workflow efficiency, and exam preparation. He teaches learners how to design parametric parts, create assemblies, and generate professional drawings. His practical approach ensures participants gain not only ACP exam competence but also the ability to apply Inventor effectively in mechanical and engineering contexts.',
       'In this course, Bernard emphasizes precision and workflow efficiency. He teaches learners how to generate 3D concepts with AI, correct geometry and topology, and produce professional design documentation. His practical approach ensures participants gain the ability to apply generative AI effectively in real design and engineering contexts.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In his Inventor Mechanical Design training, Shahul focuses on hands-on, project-based learning. He guides learners through modeling, constraints, and simulations, ensuring they can confidently apply Inventor for mechanical design tasks while preparing for ACP certification.',
       'In this course, Shahul focuses on hands-on, project-based learning. He guides learners through AI model generation, mesh cleanup, texturing, and optimization, ensuring they can confidently apply generative AI to real 3D design and visualization tasks.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ------------------------------------------- 8b. Prerequisite software link
-- Surface 11: "Minimum Software/Hardware Requirement" links the OLD TOOL. This
-- attribute ALSO holds the entire funding apparatus (PWM, eligibility table,
-- SkillsFuture/PSEA/SFEC/UTAP deep links, Appeal Process) -- NEVER rewrite it
-- wholesale. Surgical REPLACE() on the single <li> holding the Autodesk link
-- only; the course now uses generative-AI 3D tools plus Blender for refinement,
-- matching the non-WSQ twin's toolchain.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       '<li><a href="https://www.autodesk.com/products/inventor/overview" target="_blank"><span style="text-decoration: underline;">Autodesk Inventor</span></a></li>',
       '<li><a href="https://www.blender.org/download/" target="_blank"><span style="text-decoration: underline;">Blender</span></a></li>')
 WHERE entity_id = @e AND attribute_id = @a_prereq AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 9. Category placement
-- The repurpose changes the PURPOSE: the course no longer prepares learners for
-- the Autodesk ACP exam and no longer teaches Autodesk Inventor, so drop:
--   216 "Autodesk Certification Exam Prep" -- pure ACP/ACU exam-prep listing
--   222 "Autodesk Certification Exam Prep" -- duplicate listing, same members
--   213 "Autodesk Inventor" -- tool-specific listing; the course no longer
--       teaches Inventor at all (unlike 953, where Civil 3D was still taught,
--       so its tool listings were KEPT). This is the one asymmetry vs 953.
-- and join 252 "AI Courses", the master listing every AI course belongs to.
-- KEPT: 71 "Autodesk" -- broad vendor parent whose members include general
-- design courses; 182 "Certification Exam Prep" -- broad mixed parent, and the
-- course still carries a WSQ Statement of Achievement; 366 "Technical Drawing"
-- and 398 "WSQ Technical Drawing & BIM Courses" -- the accredited Skills
-- Framework mapping (BEV-TDR-4005-1.1-1 Technical Drawing) is unchanged.
-- Both sides mirrored into catalog_category_product_index or the storefront
-- listings never change.
--
-- NOTE on search redirects (checklist surface 7): all ~90 catalogsearch_query
-- rows matching 'inventor' have an EMPTY redirect column, and NO row's redirect
-- points at the old slug -- verified before writing. There is nothing to
-- retarget, so no catalogsearch_query statement is included. Blindly filling
-- them would ALSO be wrong: most are App-Inventor / inventory / Autodesk-
-- Inventor-essentials intent that belongs to OTHER live courses, not this one.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (213, 216, 222) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (213, 216, 222) AND @e IS NOT NULL;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 252, @e, COALESCE((SELECT MAX(position) FROM (SELECT position FROM catalog_category_product WHERE category_id = 252) p), 0) + 1
 WHERE @e IS NOT NULL
   AND EXISTS (SELECT 1 FROM catalog_category_entity WHERE entity_id = 252);

INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 252, @e, cp.position, 1, s.store_id, 4
  FROM catalog_category_product cp
  CROSS JOIN core_store s
 WHERE cp.category_id = 252 AND cp.product_id = @e AND s.store_id > 0 AND @e IS NOT NULL;
