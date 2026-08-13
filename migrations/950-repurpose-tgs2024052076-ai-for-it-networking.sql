-- 950: Repurpose TGS-2024052076
--   "WSQ - Pearson Vue Certified IT Specialist Networking"
--     -> "WSQ - AI for IT Networking"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-13: pivot from the Pearson VUE certification
-- track to AI-assisted network configuration, monitoring and troubleshooting.
--
-- Same shape as 933/936, which repurposed the sibling Pearson-VUE course
-- TGS-2025054471 away from the exam-prep track.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title,
-- meta_description, meta_keyword, short_description, description (LSN_DATA JSON
-- kept in sync with the visible markup), trainerprofile (the teaching paragraphs
-- that name the Pearson VUE certification only), image/small_image/thumbnail
-- labels, media-gallery label, 301 for the old bare slug, and category placement
-- (add AI Courses 252; drop the two Pearson-VUE exam-prep listings 402/435),
-- mirrored into catalog_category_product_index.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2024052076_learning_outcomes -- the supplied LO1-LO5 are
--     byte-equivalent to the live block; they are the SSG-accredited outcomes
--     registered against the unchanged SKU.
--   * course_TGS-2024052076_skills_framework -- ICT-DIT-2009-1.1 Network
--     Configuration still describes the course.
--   * course_TGS-2024052076_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; the fee table and OpenCerts wording are unaffected.
--   * whoshouldattend -- 20 generic networking/IT roles, none tool- or
--     Pearson-specific; every one still fits an AI-for-networking course.
--   * prerequisite / additional_note / venue -- funding apparatus and logistics.
--   * category 182 "Certification Exam Prep" -- the broad parent (mixed content);
--     the course still carries a WSQ Statement of Achievement. Only the two
--     Pearson-VUE-specific children are dropped (same call as migration 936).
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024052076' LIMIT 1);

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
   SET value = 'WSQ - AI for IT Networking'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for IT Networking'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to apply AI to configure, monitor and troubleshoot modern networks. Covers server and device configuration, user network access, network management tools, performance reporting, and network testing for reliability and compliance.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'AI for IT networking, AI network configuration, AI network monitoring, AI network troubleshooting, network management tools, network performance reporting, network testing, LAN, WAN, wireless networking, IPv4, IPv6, cloud networking, WSQ networking course'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL.
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-for-it-networking'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the new path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-ai-for-it-networking.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- NOTE: the old bare slug is held by this product's SYSTEM rewrite
-- (id_path 'product/<e>', is_system = 1), so a plain INSERT IGNORE silently
-- no-ops against the unique key on (request_path, store_id). Convert that row
-- in place into a permanent redirect instead; the indexer then mints a fresh
-- system row for the NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-for-it-networking.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-pearson-vue-certified-it-specialist-networking.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2024052076-rp-950-', s.store_id),
       'wsq-pearson-vue-certified-it-specialist-networking.html',
       'wsq-ai-for-it-networking.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for IT Networking'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI for IT Networking'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------ 5. Topics Covered (description + JSON)
-- The visible <p><strong>Topic N</strong></p> markup and the LSN_DATA JSON
-- comment must stay in sync. Subsections dropped: the supplied outline is
-- topic-level only. Replacement text is clean ASCII (the outgoing row carries
-- multi-byte bullet chars that would choke apply.php's utf8 connection if
-- partially rewritten -- a full replace sidesteps that entirely).
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: AI-Assisted Server and Network Device Configuration","subsecs":[]},{"title":"Topic 2: AI-Powered User Network Access and Connectivity Support","subsecs":[]},{"title":"Topic 3: AI-Enhanced Network Monitoring and Performance Management","subsecs":[]},{"title":"Topic 4: AI-Assisted Network Performance Analysis and Reporting","subsecs":[]},{"title":"Topic 5: AI-Powered Network Testing, Reliability and Compliance Validation","subsecs":[]}] -->
<p><strong>Topic 1: AI-Assisted Server and Network Device Configuration</strong></p>
<p><strong>Topic 2: AI-Powered User Network Access and Connectivity Support</strong></p>
<p><strong>Topic 3: AI-Enhanced Network Monitoring and Performance Management</strong></p>
<p><strong>Topic 4: AI-Assisted Network Performance Analysis and Reporting</strong></p>
<p><strong>Topic 5: AI-Powered Network Testing, Reliability and Compliance Validation</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Post-885 block model: this course's short_description is prose only (1000 bytes,
-- no <h2>Course Brochure</h2> tail, no SKU deep links) => a full replace is safe.
UPDATE catalog_product_entity_text
   SET value = '<p>AI for IT Networking equips participants with practical skills to use artificial intelligence to design, configure, monitor, and troubleshoot modern network environments. Learners will develop a strong foundation in networking concepts, including local and wide area networks, wireless connectivity, remote access, cloud networking, virtualization, and IPv4 and IPv6 protocols.</p>
<p>Through hands-on activities, participants will use AI tools to interpret network requirements, generate configuration recommendations, analyze device settings, create network diagrams, and produce technical documentation. They will configure and manage routers, switches, servers, endpoints, and wireless devices while applying appropriate network protocols and access controls.</p>
<p>The course also explores AI-assisted network monitoring and troubleshooting. Participants will learn to analyze logs, identify connectivity and performance issues, diagnose possible root causes, and generate step-by-step remediation plans. Emphasis is placed on validating AI recommendations, protecting sensitive configuration data, and maintaining human oversight. By the end of the course, learners will be able to combine networking knowledge with AI-assisted workflows to improve network reliability, performance, documentation, and operational efficiency.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------------- 7. Trainer bios
-- Each bio is two paragraphs: para 1 = career CREDENTIALS (certifications,
-- employers, degrees) -- FACTS, left untouched; para 2 = a course-teaching claim
-- scoped to the retired Pearson VUE certification -- retargeted to AI-assisted
-- networking. Single-line REPLACE() on the full paragraph string (a multi-line
-- pattern no-ops against the WYSIWYG blob's CRLF line endings).
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In the Pearson VUE Certified IT Specialist &ndash; Networking course, Truman equips learners with the skills to design, configure, and troubleshoot modern network infrastructures. His training approach emphasizes hands-on lab exercises and real-world network management scenarios. Learners benefit from his comprehensive understanding of routing, switching, and cloud-based networking models, gaining the confidence to implement and maintain secure and scalable enterprise networks.',
       'In this course, Truman equips learners with the skills to use AI to design, configure, and troubleshoot modern network infrastructures. His training approach emphasizes hands-on lab exercises and real-world network management scenarios. Learners benefit from his comprehensive understanding of routing, switching, and cloud-based networking models, gaining the confidence to apply AI-assisted workflows to implement and maintain secure and scalable enterprise networks.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Alec helps participants build a strong foundation in networking technologies and protocols. His sessions focus on network configuration, system security, and troubleshooting, with an emphasis on practical implementation and real-world application. Learners benefit from his ability to translate complex networking concepts into accessible, step-by-step guidance that prepares them for both professional certification and real-world network administration roles.',
       'In this course, Alec helps participants build a strong foundation in networking technologies and protocols alongside AI-assisted workflows. His sessions focus on network configuration, system security, and troubleshooting, with an emphasis on practical implementation and real-world application. Learners benefit from his ability to translate complex networking concepts into accessible, step-by-step guidance that prepares them for real-world network administration roles.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In this course, Dr. Ang provides learners with a structured understanding of network design, administration, and troubleshooting aligned with industry best practices. His sessions emphasize network architecture, performance optimization, and cloud-based networking strategies. Participants gain in-depth exposure to both traditional and modern network systems, empowering them to achieve technical mastery and professional recognition under the Pearson VUE Certified IT Specialist framework.',
       'In this course, Dr. Ang provides learners with a structured understanding of AI-assisted network design, administration, and troubleshooting aligned with industry best practices. His sessions emphasize network architecture, performance optimization, and cloud-based networking strategies. Participants gain in-depth exposure to both traditional and AI-enhanced network operations, empowering them to apply AI responsibly to improve network reliability and efficiency.')
 WHERE entity_id = @e AND attribute_id = @a_tprof AND store_id = 0 AND @e IS NOT NULL;

-- ----------------------------------------------------- 8. Category placement
-- The repurpose changes the SUBJECT: the course no longer prepares learners for
-- a Pearson VUE exam, so drop the two exam-prep listings that are ~95% Pearson
-- VUE certification courses (same call as migration 936 for TGS-2025054471):
--   435 "Pearson VUE Certification Exam Prep"
--   402 "IT Specialists Exam Prep"
-- and join 252 "AI Courses", the master listing every AI course belongs to.
-- Both sides mirrored into catalog_category_product_index or the storefront
-- listings never change.
DELETE FROM catalog_category_product
 WHERE product_id = @e AND category_id IN (402, 435) AND @e IS NOT NULL;

DELETE FROM catalog_category_product_index
 WHERE product_id = @e AND category_id IN (402, 435) AND @e IS NOT NULL;

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
