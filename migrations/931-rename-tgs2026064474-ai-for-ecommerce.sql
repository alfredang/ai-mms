-- 931: Rename TGS-2026064474
--        "CASL - Building a Successful eCommerce Store with WooCommerce"
--      -> "CASL - AI for eCommerce"
--
-- Course code (SKU) is UNCHANGED - TGS-2026064474 stays (the CASL registration
-- created by 757), so the brochure PDF path, funding-validity block and every
-- deep link keyed on the course code remain correct. The course keeps its CASL
-- segment prefix (same SKU, no funding change requested). Follows the 855/930
-- playbook for TGS- renames.
--
-- Scope of this file:
--   1. name / meta_title / meta_description / meta_keyword / image labels -> new title
--   2. url_key -> casl-ai-for-ecommerce ; url_path deleted at every scope so
--      the Catalog URL Rewrites indexer regenerates it
--   3. explicit 301 from the old bare slug, guarded against ANY existing row on
--      that request_path (pre-reindex the system row still occupies it and the
--      indexer's rewrite history recreates the 301s at reindex; this insert is
--      belt-and-braces for the bare path - see 647/855). Legacy alias rewrites
--      (wsq-wordpress-cms-1082, wsq-ecommerce-woocommerce-course, the pre-CASL
--      wsq-building-* slugs - ~40 rows on SG) are repointed off the old slug so
--      they don't 301-chain through it.
--   4. short_description replaced with the new "About This Course" copy. This
--      course's sections (Brochure / Certification / Skills Framework / Funding
--      Validity) already live in per-course cms/block rows on prod, so there is
--      no section tail to splice - full replace is correct here.
--   5. description (Course Outline) -> the 5 new topics, keeping the existing
--      <h3 class="course-topic-h3"> markup shape (this course has no LSN_DATA
--      header). The user supplied topic titles only - no sub-bullets invented.
--   6. cms_block course_TGS-2026064474_learning_outcomes CREATED (this course
--      predates the block extraction and had no Learning Outcomes section
--      anywhere) with the official LO1-LO6, matching the 915 block shape.
--   7. media gallery per-image label
--   8. search-term redirects retargeted off BOTH old slugs (casl-building-* and
--      the pre-CASL wsq-building-* - 28 live rows on SG)
--
-- meta_title deliberately omits the segment prefix and the brand suffix:
-- MMD_Seotitle composes the <title> at render time (Block/Html/Head.php),
-- prepending the funding prefix for TGS- SKUs and appending the brand postfix.
--
-- NOT rewritten:
--   - trainerprofile - the five bios reference "WooCommerce training"
--     generically and never quote the course title (verified on prod). The
--     course still teaches WooCommerce (see the LOs), so those stay correct.
--   - brochure / certification / skills_framework / funding_validity /
--     funding_and_grant cms blocks - keyed on the unchanged SKU, title-free.
--   - whoshouldattend / prerequisite - still accurate for the revised course.
--
-- The cover PNG and the brochure PDF still bake the old title - regenerate both
-- after this applies (cover via MMD_CourseImage, brochure via
-- scripts/local-dev/batch-generate-brochures.php --wid=1 --sku-like=TGS-2026064474).
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops). Idempotent - re-runnable.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064474' LIMIT 1);

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'description');
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_keyword');

-- ---------------------------------------------------------------- 1. varchars

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'CASL - AI for eCommerce' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- No segment prefix and no brand suffix - MMD_Seotitle supplies both (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'AI for eCommerce' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'AI for eCommerce training in Singapore. Use AI to set up, manage and optimise your WooCommerce online store - product content, payments, shipping, promotions and AI-assisted analytics.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'casl-ai-for-ecommerce' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "CASL -" prefix) - they are alt text on
-- the course cover, which itself renders without the prefix.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'AI for eCommerce' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'AI for eCommerce' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'AI for eCommerce' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped overrides so store 0 wins for the renamed attrs.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_uk, @a_il, @a_sil, @a_til);

-- ------------------------------------------------- 2. url_path at all scopes
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 3. 301 from the old slug
-- Drop any WRONG-target non-system squatter on the old path first (see 647:
-- INSERT against a stale row silently no-ops and the 301 never ships).
DELETE FROM core_url_rewrite
WHERE is_system = 0
  AND request_path = 'casl-building-a-successful-ecommerce-store-with-woocommerce.html'
  AND target_path <> 'casl-ai-for-ecommerce.html'
  AND @e IS NOT NULL;

-- Guarded against ANY row on the request_path: pre-reindex the system row still
-- holds it (the indexer's rewrite history takes over at reindex); post-reindex
-- this fills the bare-slug 301 if the indexer didn't.
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_tgs2026064474_casl_old_', s.store_id),
       'casl-building-a-successful-ecommerce-store-with-woocommerce.html',
       'casl-ai-for-ecommerce.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0 AND @e IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM core_url_rewrite c
    WHERE c.store_id = s.store_id
      AND c.request_path = 'casl-building-a-successful-ecommerce-store-with-woocommerce.html');

-- Repoint legacy alias rewrites (wsq-wordpress-cms-1082.html,
-- wsq-ecommerce-woocommerce-course.html, wsq-building-* and their category
-- variants) so they don't 301-chain through the retired slug. Category-prefixed
-- targets keep their prefix - only the product filename changes.
UPDATE core_url_rewrite
SET target_path = REPLACE(target_path,
      'casl-building-a-successful-ecommerce-store-with-woocommerce.html',
      'casl-ai-for-ecommerce.html')
WHERE is_system = 0 AND @e IS NOT NULL
  AND target_path LIKE '%casl-building-a-successful-ecommerce-store-with-woocommerce.html';

-- ---------------------------------- 4. short_description (About This Course)
-- Full replace: this course's short_description holds only the intro copy (the
-- Brochure / Certification / Skills Framework sections live in cms/block rows),
-- so there is no tail to preserve.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sd, 0, @e, '<p>AI for eCommerce equips participants with practical skills to use artificial intelligence to create, manage and optimise online retail operations. Learners will explore how AI can support product research, generate compelling product descriptions and visual content, personalise customer experiences, automate routine tasks and improve store performance.</p>
<p>The course covers essential eCommerce functions, including product catalogue management, inventory, payment gateways, shipping options, order fulfilment and search engine optimisation. Participants will apply generative AI to develop marketing content, customer communications, promotional campaigns and personalised product recommendations. They will also learn to use AI-powered chatbots and automation tools to respond to enquiries, support customers and streamline order-related workflows.</p>
<p>Participants will analyse sales trends, customer behaviour and key performance indicators using AI-assisted analytics. These insights will help them identify opportunities, forecast demand and make data-driven decisions to improve conversions and customer retention. Responsible AI practices, including data privacy, content accuracy and human review, are also addressed.</p>
<p>By the end of the course, participants will be able to integrate AI into key eCommerce processes, enhance customer engagement, improve operational efficiency and develop effective strategies for sustainable online business growth.</p>' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_sd;

-- ----------------------------------------------- 5. description (Course Outline)
-- Same markup shape as the current value (h3.course-topic-h3 per topic).
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: AI-Enabled eCommerce Store Setup and Content Management</h3>
<h3 class="course-topic-h3">Topic 2: AI-Assisted Product Catalogue and Web Content Management</h3>
<h3 class="course-topic-h3">Topic 3: Payment, Shipping and Customer Experience Optimisation</h3>
<h3 class="course-topic-h3">Topic 4: AI-Powered Sales, Order and Promotion Management</h3>
<h3 class="course-topic-h3">Topic 5: eCommerce Analytics and Performance Optimisation</h3>' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_desc;

-- meta_keyword: lead with the new course name.
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mk, 0, @e, 'CASL, AI for eCommerce, eCommerce, WooCommerce, Artificial Intelligence, Online Store, eCommerce Analytics, CASL Funding' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mk;

-- ---------------------------- 6. Learning Outcomes cms/block (LO1-LO6, NEW)
-- This course had no learning_outcomes block (and no Learning Outcomes section
-- in short_description), so the "What You'll Learn" card was empty. Create the
-- block in the 915 shape, then converge content on re-runs.
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064474 - Learning Outcomes', 'course_TGS-2026064474_learning_outcomes', '', NOW(), NOW(), 1 FROM dual
WHERE @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_TGS-2026064474_learning_outcomes');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
WHERE identifier = 'course_TGS-2026064474_learning_outcomes' AND @e IS NOT NULL;

UPDATE cms_block
SET content = '<p>By the end of the course, learners will be able to:</p>
<ul>
<li>LO1: Setup and monitor WooCommerce CMS to ensure adherence to guidelines and policies</li>
<li>LO2: Edit and curate product website on WooCommerce CMS</li>
<li>LO3: Maintain product web content on WooCommerce CMS</li>
<li>LO4: Recommend payment and shipping methods on WooCommerce CMS to improve customer experience</li>
<li>LO5: Manage issues related to WooCommerce CMS such as sales, out-of-stock, promotion etc.</li>
<li>LO6: Manage WooCommerce CMS performance</li>
</ul>'
WHERE identifier = 'course_TGS-2026064474_learning_outcomes' AND @e IS NOT NULL;

-- ------------------------------------------- 7. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'AI for eCommerce'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- --------------------------------------- 8. retarget search-term redirects
-- 28 live SG rows point at the old slugs (both the current casl-building-* and
-- the pre-CASL wsq-building-*, incl. the old course code TGS-2020503869 as a
-- query). Search redirects are DATA - this was ALSO applied live on prod (see
-- memory feedback_search_redirects_always_apply_live).
UPDATE catalogsearch_query
SET redirect = 'https://www.tertiarycourses.com.sg/casl-ai-for-ecommerce.html',
    is_processed = 1
WHERE store_id = 1 AND @e IS NOT NULL
  AND (redirect LIKE '%casl-building-a-successful-ecommerce-store-with-woocommerce%'
    OR redirect LIKE '%wsq-building-a-successful-ecommerce-store-with-woocommerce%');
