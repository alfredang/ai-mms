-- 931: Rename TGS-2026064175
--        "CASL - Running a Successful eCommerce Store with Shopify"
--      -> "CASL - Build Your Own eCommerce Store with AI Vibe Coding"
--      + new Course Outline (description) and About This Course (short_description)
--
-- Course code (SKU) is UNCHANGED - TGS-2026064175 stays, so every funding /
-- SkillsFuture deep link keyed on the course code remains correct. Follows the
-- 851/853/855 TGS- rename playbook via the 925/929/930 precedent shapes.
--
-- Scope of this file:
--   1. name / meta_title / meta_description / image labels -> new title
--   2. url_key -> casl-build-your-own-ecommerce-store-with-ai-vibe-coding ;
--      url_path deleted at every scope so the Catalog URL Rewrites indexer
--      regenerates it
--   3. 301 the old slug at the new one (repoint the pre-reindex system row +
--      INSERT IGNORE fallback, both scopes), and repoint every legacy alias
--      rewrite that 301s INTO the old slug (ecommerce-with-shopify,
--      wsq-shopify-ecommerce, wsq-shopify-ecommerce-course,
--      wsq-web-design-html-css-course-1109,
--      wsq-running-a-successful-ecommerce-store-with-shopify, incl. all their
--      category-prefixed variants) straight at the new bare slug so inbound
--      links take one hop, not a chain
--   4. description -> the new 5-topic Course Outline
--   5. short_description -> the new 3-paragraph About This Course. FULL
--      replace, deliberately dropping the old "Shopify Partner" / "PSG Grant
--      for Shopify" marketing tail - it contradicts the new AI-Vibe-Coding
--      course identity, and every load-bearing section (Learning Outcomes /
--      Brochure / Skills Framework / Certification / Funding / Funding
--      Validity) lives in the per-course cms/block rows keyed on the
--      unchanged SKU, not in short_description.
--   6. meta_keyword refreshed to lead with the new course name
--   7. media gallery per-image label
--   8. search-term redirects: 30 live SG rows point at the old slug (incl.
--      the old-title queries and the Shopify queries - the course still
--      teaches Shopify per its accredited LOs, so they stay pointed here) -
--      retarget by full SG-domain URL (partner-safe); also applied live on
--      prod per feedback_search_redirects_always_apply_live
--
-- meta_title deliberately omits BOTH the leading segment prefix and the
-- "| Tertiary Courses Singapore" suffix: MMD_Seotitle composes the <title> at
-- render time, prepending the funding prefix for any SG TGS- SKU and appending
-- the brand postfix (Block/Html/Head.php). Baking either in yields the
-- duplicated title tag that 853 had to clean up. (The old rows had both baked
-- in at store 0 AND store 1 - both replaced/cleared here.)
--
-- NOT rewritten (verified against prod before authoring):
--   - cms_block course_TGS-2026064175_learning_outcomes: LO1-LO6 already match
--     the requested outcomes verbatim (Shopify store/CMS setup, content
--     curation, theme customisation, orders, payment/shipping, marketing)
--   - cms_block course_TGS-2026064175_brochure + _certification +
--     _skills_framework + _funding_and_grant + _funding_validity: keyed on the
--     unchanged SKU, no old-title mention
--   - trainerprofile: mentions "her Shopify training" generically, never the
--     old course title (checked LOCATE) - not a leak, left alone
--   - news_from/to_date Funding Validity window: unchanged registration
--
-- The cover PNG and brochure PDF bake the old title - regenerate both on prod
-- after this applies (MMD_CourseImage strips the "CASL - " prefix at render).
--
-- Partner-safe: every statement guarded on @e (TGS- SKUs only exist on SG; on
-- MY/GH @e IS NULL and the whole file no-ops); rewrite/search statements are
-- additionally guarded on the SG store. Idempotent - re-runnable.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026064175' LIMIT 1);
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_mk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_keyword');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'description');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');

-- ---------------------------------------------------------------- 1. varchars

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'CASL - Build Your Own eCommerce Store with AI Vibe Coding' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- No segment prefix and no brand suffix - MMD_Seotitle supplies both (see header).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'Build Your Own eCommerce Store with AI Vibe Coding Training' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'Build Your Own eCommerce Store with AI Vibe Coding training in Singapore. Use AI-assisted vibe coding to design, build and launch a fully functional online store with product catalogue, checkout, payments and SEO.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'casl-build-your-own-ecommerce-store-with-ai-vibe-coding' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image labels carry the plain title (no "CASL -" prefix) - they are alt text
-- on the course cover, which itself renders without the prefix (Cover.php
-- cleanTitle strips WSQ/CASL/IBF).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'Build Your Own eCommerce Store with AI Vibe Coding' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'Build Your Own eCommerce Store with AI Vibe Coding' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'Build Your Own eCommerce Store with AI Vibe Coding' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear any store-scoped overrides so store 0 wins for the renamed attrs
-- (prod has meta_title + meta_description baked at store 1 - see header).
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0
  AND attribute_id IN (@a_name, @a_mt, @a_md, @a_uk, @a_il, @a_sil, @a_til);

-- ------------------------------------------------- 2. url_path at all scopes
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_up;

-- --------------------------------------------------- 3. 301 from the old slug
-- Repoint the existing rewrite row (the system row still holds the old
-- request_path until reindex) and force it permanent + manual; create the row
-- where none exists (both scopes).
UPDATE core_url_rewrite
  SET target_path = 'casl-build-your-own-ecommerce-store-with-ai-vibe-coding.html',
      options = 'RP', is_system = 0
  WHERE @sg = 1 AND @e IS NOT NULL
    AND request_path = 'casl-running-a-successful-ecommerce-store-with-shopify.html'
    AND store_id IN (0, 1);

INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('casl-running-a-successful-ecommerce-store-with-shopify.html'), '-', s.store_id),
       'casl-running-a-successful-ecommerce-store-with-shopify.html',
       'casl-build-your-own-ecommerce-store-with-ai-vibe-coding.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = 'casl-running-a-successful-ecommerce-store-with-shopify.html'
                    AND x.store_id = s.store_id);

-- Legacy alias rewrites that 301 INTO the old slug (bare AND category-prefixed
-- targets) - repoint straight at the new bare slug so inbound links take one
-- hop, not a chain. System category rows regenerate + auto-301 on reindex.
UPDATE core_url_rewrite
  SET target_path = 'casl-build-your-own-ecommerce-store-with-ai-vibe-coding.html'
  WHERE @sg = 1 AND @e IS NOT NULL
    AND is_system = 0
    AND target_path LIKE '%casl-running-a-successful-ecommerce-store-with-shopify.html'
    AND request_path <> 'casl-running-a-successful-ecommerce-store-with-shopify.html';

-- --------------------------------------------- 4. description (Course Outline)
-- New 5-topic outline as provided; authored in the dominant catalog shape
-- (h3.course-topic-h3) matching the row it replaces.
UPDATE catalog_product_entity_text
  SET value = '<h3 class="course-topic-h3">Topic 1: AI Vibe Coding for eCommerce Store Setup and CMS</h3>\n<h3 class="course-topic-h3">Topic 2: Product Catalogue and Web Content Management</h3>\n<h3 class="course-topic-h3">Topic 3: AI-Assisted Storefront and Customer Experience Customisation</h3>\n<h3 class="course-topic-h3">Topic 4: Shopping Cart, Checkout and Order Management</h3>\n<h3 class="course-topic-h3">Topic 5: Payment, Tax, Shipping and Fulfilment Integration</h3>'
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_desc AND store_id = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_desc;

-- ---------------------------------- 5. short_description (About This Course)
-- FULL replace (see header): the three new paragraphs; the old Shopify
-- Partner / PSG Grant tail is deliberately dropped. Plain UPDATE to a
-- constant - naturally idempotent.
UPDATE catalog_product_entity_text
  SET value = CONCAT(
    '<p>Build Your Own eCommerce Store with AI Vibe Coding equips participants with the practical skills to design, develop, and launch a fully functional online store using AI-assisted coding tools. Through natural-language instructions, learners will use AI to generate and refine storefront layouts, product pages, shopping carts, checkout workflows, customer accounts, and administrative features&mdash;without requiring extensive programming experience.</p>\n',
    '<p>Participants will learn to manage product catalogues, inventory, orders, customers, promotions, and sales data through a customised eCommerce management system. The course also covers responsive web design, payment gateway integration, search engine optimisation, testing, debugging, security, and deployment.</p>\n',
    '<p>By the end of the course, participants will have built a customised eCommerce store tailored to their business needs. They will also be able to use AI Vibe Coding techniques to enhance store features, troubleshoot issues, automate routine operations, analyse customer behaviour, and make data-driven improvements that increase engagement and support business growth.</p>')
  WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_sd AND store_id = 0;

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_sd;

-- ------------------------------------------------------------ 6. meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mk, 0, @e, 'Build your own eCommerce store, AI vibe coding eCommerce course, AI-assisted online store development, vibe coding web store, eCommerce store setup training Singapore, AI coding for eCommerce, CASL eCommerce course, Shopify store course, online store builder training, AI eCommerce automation' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e AND @e IS NOT NULL AND store_id <> 0 AND attribute_id = @a_mk;

-- ------------------------------------------------ 7. media gallery image label
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Build Your Own eCommerce Store with AI Vibe Coding'
WHERE g.entity_id = @e AND @e IS NOT NULL;

-- ------------------------------------------- 8. search-term redirects (30 rows)
-- Retarget every live row pointing at the old slug (incl. the old-title and
-- Shopify queries - the accredited LOs still teach Shopify, so this page stays
-- the right target). REPLACE on the full SG-domain URL - partner-safe.
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'https://www.tertiarycourses.com.sg/casl-running-a-successful-ecommerce-store-with-shopify.html', 'https://www.tertiarycourses.com.sg/casl-build-your-own-ecommerce-store-with-ai-vibe-coding.html')
  WHERE redirect LIKE '%casl-running-a-successful-ecommerce-store-with-shopify.html%';
