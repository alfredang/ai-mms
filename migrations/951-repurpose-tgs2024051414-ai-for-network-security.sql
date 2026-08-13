-- 951: Repurpose TGS-2024051414
--   "WSQ - Pearson Vue Certified IT Specialist Network Security Training"
--     -> "WSQ - AI for Network Security"
-- SKU unchanged (every SkillsFuture / SFEC / SFC / PSEA deep link is keyed on it).
-- Content supplied by admin, 2026-08-13: pivot from the Pearson VUE certification
-- track to AI-assisted threat detection, risk assessment and incident response.
--
-- Sibling of 950 (TGS-2024052076) and 933/936 (TGS-2025054471) -- same shape.
--
-- Surfaces touched: name, url_key (+ url_path delete at every scope), meta_title,
-- meta_description, meta_keyword, short_description, description (LSN_DATA JSON
-- kept in sync with the visible markup), trainerprofile (the one teaching
-- paragraph that names the Pearson VUE certification), image/small_image/thumbnail
-- labels, media-gallery label, 301 for the old bare slug, and category placement
-- (add AI Courses 252; drop the two Pearson-VUE exam-prep listings 402/435),
-- mirrored into catalog_category_product_index.
--
-- Deliberately UNCHANGED (verified against live data before writing):
--   * course_TGS-2024051414_learning_outcomes -- the supplied LO1-LO4 are
--     equivalent to the live block (which differs only by &nbsp; entities); they
--     are the SSG-accredited outcomes registered against the unchanged SKU.
--   * course_TGS-2024051414_skills_framework -- ICT-DIT-4024-1.1 Network
--     Security still describes the course.
--   * course_TGS-2024051414_certification / _funding_and_grant / _brochure --
--     keyed on the SKU; the fee table and OpenCerts wording are unaffected.
--   * whoshouldattend -- 20 generic security/networking roles, none tool- or
--     Pearson-specific; every one still fits an AI-for-network-security course.
--   * prerequisite / additional_note / venue -- funding apparatus and logistics.
--   * category 182 "Certification Exam Prep" -- the broad parent (mixed content);
--     the course still carries a WSQ Statement of Achievement. Only the two
--     Pearson-VUE-specific children are dropped (same call as migration 936).
--     Categories 161 / 364 / 386 (IT Security, Cyber Security & PDPA, Network
--     Securities) stay -- they describe the NEW content correctly.
--   * image/small_image/thumbnail PATHS -- filesystem paths, not display text;
--     renaming them 404s the file. The storefront renders course_image_url.
--   * cover PNG (course_image_url) -- re-rendered out of band from the admin.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => every
-- statement below is a guarded no-op there. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024051414' LIMIT 1);

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
   SET value = 'WSQ - AI for Network Security'
 WHERE entity_id = @e AND attribute_id = @a_name AND @e IS NOT NULL;

-- ------------------------------------------------------- 2. SEO meta
-- meta_title: plain title. MMD_Seotitle prepends "WSQ funded" for SG TGS- SKUs
-- and appends the brand postfix at render time -- baking either in duplicates it.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Network Security'
 WHERE entity_id = @e AND attribute_id = @a_mtitle AND @e IS NOT NULL;

UPDATE catalog_product_entity_varchar
   SET value = 'Learn to apply AI to network threat detection, vulnerability assessment, risk management and incident response. Covers traffic and log analysis, segmentation, access control, encryption, firewall policies and intrusion detection.'
 WHERE entity_id = @e AND attribute_id = @a_mdesc AND @e IS NOT NULL;

UPDATE catalog_product_entity_text
   SET value = 'AI for network security, AI threat detection, AI vulnerability assessment, network risk management, AI incident response, network traffic analysis, intrusion detection, firewall policies, network segmentation, access control, endpoint protection, threat intelligence, WSQ cybersecurity course'
 WHERE entity_id = @e AND attribute_id = @a_mkey AND @e IS NOT NULL;

-- --------------------------------------------------------- 3. URL key
-- Delete url_path at EVERY scope so the Catalog URL Rewrites indexer regenerates
-- it; a surviving store-scoped row shadows the new URL.
UPDATE catalog_product_entity_varchar
   SET value = 'wsq-ai-for-network-security'
 WHERE entity_id = @e AND attribute_id = @a_urlk AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
 WHERE entity_id = @e AND attribute_id = @a_urlp AND @e IS NOT NULL;

-- Remove any non-system squatter on the new path before inserting the 301,
-- so the INSERT IGNORE below cannot silently no-op against a stale row.
DELETE FROM core_url_rewrite
 WHERE is_system = 0
   AND request_path = 'wsq-ai-for-network-security.html'
   AND @e IS NOT NULL;

-- Explicit 301 for the old BARE slug (the indexer auto-301s the category paths).
-- NOTE: the old bare slug is held by this product's SYSTEM rewrite
-- (id_path 'product/<e>', is_system = 1), so a plain INSERT IGNORE silently
-- no-ops against the unique key on (request_path, store_id). Convert that row
-- in place into a permanent redirect instead; the indexer then mints a fresh
-- system row for the NEW slug.
UPDATE core_url_rewrite
   SET target_path = 'wsq-ai-for-network-security.html',
       is_system   = 0,
       options     = 'RP'
 WHERE request_path = 'wsq-pearson-vue-certified-it-specialist-network-security-training.html'
   AND id_path = CONCAT('product/', @e)
   AND @e IS NOT NULL;

-- Belt-and-braces for any store that had no system row on the old slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('TGS-2024051414-rp-951-', s.store_id),
       'wsq-pearson-vue-certified-it-specialist-network-security-training.html',
       'wsq-ai-for-network-security.html',
       0, 'RP'
  FROM core_store s
 WHERE s.store_id > 0 AND @e IS NOT NULL;

-- ------------------------------------------------- 4. Image alt text
-- Plain title (no "WSQ - " prefix): the cover itself strips the prefix.
UPDATE catalog_product_entity_varchar
   SET value = 'AI for Network Security'
 WHERE entity_id = @e AND attribute_id IN (@a_ilab, @a_slab, @a_tlab) AND @e IS NOT NULL;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = 'AI for Network Security'
 WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------ 5. Topics Covered (description + JSON)
-- The visible <p><strong>Topic N</strong></p> markup and the LSN_DATA JSON
-- comment must stay in sync. Subsections dropped: the supplied outline is
-- topic-level only. Four topics (was four) -- matches LO1-LO4.
UPDATE catalog_product_entity_text
   SET value = '<!-- LSN_DATA: [{"title":"Topic 1: AI-Assisted Network Threat and Vulnerability Analysis","subsecs":[]},{"title":"Topic 2: AI-Powered Network Risk Assessment and Management Planning","subsecs":[]},{"title":"Topic 3: Designing and Implementing AI-Enhanced Network Security Measures","subsecs":[]},{"title":"Topic 4: AI-Assisted Security Incident Documentation and Response","subsecs":[]}] -->
<p><strong>Topic 1: AI-Assisted Network Threat and Vulnerability Analysis</strong></p>
<p><strong>Topic 2: AI-Powered Network Risk Assessment and Management Planning</strong></p>
<p><strong>Topic 3: Designing and Implementing AI-Enhanced Network Security Measures</strong></p>
<p><strong>Topic 4: AI-Assisted Security Incident Documentation and Response</strong></p>'
 WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0 AND @e IS NOT NULL;

-- ---------------------------------------------- 6. About This Course (sdesc)
-- Post-885 block model: this course's short_description is prose only (no
-- <h2>Course Brochure</h2> tail, no SKU deep links) => a full replace is safe.
UPDATE catalog_product_entity_text
   SET value = '<p>AI for Network Security equips participants with practical skills to apply artificial intelligence to network monitoring, threat detection, vulnerability assessment, and incident response. Learners will explore how AI can analyze network traffic, system logs, device activity, and security alerts to identify suspicious behaviour, emerging threats, and potential control gaps.</p>
<p>Through hands-on activities, participants will use AI-assisted workflows to assess network risks, detect anomalies, analyze vulnerabilities, and prioritize security incidents. The course covers network segmentation, access control, authentication, encryption, endpoint protection, firewall policies, intrusion detection, and defence-in-depth strategies across different operating environments.</p>
<p>Participants will also learn to use AI to summarize threat intelligence, investigate security incidents, recommend remediation measures, automate repetitive monitoring tasks, and produce security reports. Emphasis is placed on validating AI-generated findings, reducing false positives, protecting confidential information, and maintaining human oversight. By the end of the course, learners will be able to use AI responsibly to strengthen network defences, accelerate threat analysis, and improve organizational cyber resilience.</p>'
 WHERE entity_id = @e AND attribute_id = @a_sdesc AND store_id = 0 AND @e IS NOT NULL;

-- -------------------------------------------------------- 7. Trainer bios
-- Five bios, each two paragraphs: para 1 = career CREDENTIALS -- FACTS, left
-- untouched; para 2 = a course-teaching claim. Only Agus Salim's names the
-- retired Pearson VUE certification, so only that one is retargeted; the other
-- four describe network-security teaching generically and stay accurate.
-- Single-line REPLACE() on the full paragraph string (a multi-line pattern
-- no-ops against the WYSIWYG blob's CRLF line endings).
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'In the Pearson VUE Certified IT Specialist &ndash; Network Security course, Agus emphasizes practical, hands-on learning in network defense and incident response. His sessions cover intrusion detection, firewall configuration, and best practices for securing digital assets. Learners benefit from his real-world experience in implementing enterprise-grade security solutions that protect systems and data in both on-premise and cloud environments.',
       'In this course, Agus emphasizes practical, hands-on learning in AI-assisted network defense and incident response. His sessions cover intrusion detection, firewall configuration, and best practices for securing digital assets. Learners benefit from his real-world experience in implementing enterprise-grade security solutions that protect systems and data in both on-premise and cloud environments.')
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
