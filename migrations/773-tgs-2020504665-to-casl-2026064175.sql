-- 773: Repurpose + re-register WSQ course
--   "WSQ - Running a Successful eCommerce Store with Shopify" (TGS-2020504665)
--   -> "CASL - Running a Successful eCommerce Store with Shopify" (TGS-2026064175)
-- The SKU CHANGES (new SSG registration). Content is retained — only the
-- name prefix, SKU references (funding/SFEC/SFC links), URL, SEO meta,
-- labels, cover and per-SKU cms_block identifiers change. Also remaps
-- catalogsearch_query redirects from the old wsq- URLs to the new casl- URL.
-- Partner-safe: TGS- SKUs absent on MY/GH => @e NULL => guarded no-op;
-- redirect REPLACE keys on the full SG-domain URL.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020504665');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- SKU re-registration (guarded: only when the new SKU is not already taken)
UPDATE catalog_product_entity SET sku = 'TGS-2026064175'
  WHERE entity_id = @e
    AND NOT EXISTS (SELECT 1 FROM (SELECT sku FROM catalog_product_entity WHERE sku = 'TGS-2026064175') x);

-- Name + labels + fresh cover (rendered with the CASL chip replacing WSQ)
UPDATE catalog_product_entity_varchar SET value = 'CASL - Running a Successful eCommerce Store with Shopify'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064175-20260722-183259.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'CASL - Running a Successful eCommerce Store with Shopify'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope (this course has store 0 + 1 rows)
UPDATE catalog_product_entity_varchar SET value = 'casl-running-a-successful-ecommerce-store-with-shopify'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta (meta_title + meta_keyword exist at BOTH store 0 and 1 — no store filter)
UPDATE catalog_product_entity_varchar SET value = REPLACE(value, 'WSQ', 'CASL')
  WHERE entity_id = @e AND attribute_id = @a_mt;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ', 'CASL')
  WHERE entity_id = @e AND attribute_id = @a_mk;

-- short_description: repoint every old TGS reference (business.gov.sg /
-- MySkillsFuture funding links + inline mention) to the new registration,
-- and retitle old-name / intro-copy mentions.
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'TGS-2020504665', 'TGS-2026064175')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ - Running a Successful eCommerce Store with Shopify', 'CASL - Running a Successful eCommerce Store with Shopify')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ-certified course', 'CASL-certified course')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ Shopify course', 'CASL Shopify course')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Per-SKU cms_blocks: rename identifiers + repoint content to the new SKU
UPDATE cms_block SET identifier = 'course_TGS-2026064175_brochure',
    title = REPLACE(title, 'TGS-2020504665', 'TGS-2026064175'),
    content = REPLACE(content, 'TGS-2020504665', 'TGS-2026064175')
  WHERE identifier = 'course_TGS-2020504665_brochure';
UPDATE cms_block SET identifier = 'course_TGS-2026064175_learning_outcomes',
    title = REPLACE(title, 'TGS-2020504665', 'TGS-2026064175'),
    content = REPLACE(content, 'TGS-2020504665', 'TGS-2026064175')
  WHERE identifier = 'course_TGS-2020504665_learning_outcomes';

-- Search-term redirects: remap rows pointing at the old wsq- URLs (current
-- flat URL + a legacy alias that 301s into it) to the new casl- URL so no
-- 301 chain / dead-end is introduced (755/762 precedent).
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect,
    'https://www.tertiarycourses.com.sg/wsq-running-a-successful-ecommerce-store-with-shopify.html',
    'https://www.tertiarycourses.com.sg/casl-running-a-successful-ecommerce-store-with-shopify.html')
  WHERE redirect LIKE '%wsq-running-a-successful-ecommerce-store-with-shopify.html%';
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect,
    'https://www.tertiarycourses.com.sg/wsq-shopify-ecommerce-course.html',
    'https://www.tertiarycourses.com.sg/casl-running-a-successful-ecommerce-store-with-shopify.html')
  WHERE redirect LIKE '%wsq-shopify-ecommerce-course.html%';
