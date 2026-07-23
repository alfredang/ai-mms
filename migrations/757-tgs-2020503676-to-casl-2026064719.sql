-- 757: Repurpose + re-register WSQ course
--   "WSQ - Design Thinking Course for Businesses" (TGS-2020503676)
--   -> "CASL - Design Thinking Course for Businesses" (TGS-2026064719)
-- The SKU CHANGES (new SSG registration). Content is retained — only the
-- name prefix, SKU references (funding/SFEC/SFC links), URL, SEO meta,
-- labels, cover and per-SKU cms_block identifiers change. Search-term
-- redirects pointing at the old product URL are repointed to the new one.
-- Partner-safe: TGS- SKUs absent on MY/GH => @e NULL => guarded no-op; the
-- search-redirect REPLACE only matches the SG domain.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020503676');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- SKU re-registration (guarded: only when the new SKU is not already taken)
UPDATE catalog_product_entity SET sku = 'TGS-2026064719'
  WHERE entity_id = @e
    AND NOT EXISTS (SELECT 1 FROM (SELECT sku FROM catalog_product_entity WHERE sku = 'TGS-2026064719') x);

-- Name + labels + fresh cover (rendered with the CASL chip replacing WSQ)
UPDATE catalog_product_entity_varchar SET value = 'CASL - Design Thinking Course for Businesses'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064719-20260723-000000.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'CASL - Design Thinking Course for Businesses'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope
UPDATE catalog_product_entity_varchar SET value = 'casl-design-thinking-course-for-businesses'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta
UPDATE catalog_product_entity_varchar SET value = 'CASL Design Thinking Course for Businesses | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt;
UPDATE catalog_product_entity_varchar SET value = REPLACE(value, 'WSQ funding subsidy', 'CASL funding subsidy')
  WHERE entity_id = @e AND attribute_id = @a_md;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ', 'CASL')
  WHERE entity_id = @e AND attribute_id = @a_mk;

-- short_description: repoint every old TGS reference (SFEC / SFC funding
-- links) to the new registration, and retitle old-name mentions (brochure
-- link text and titles).
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'TGS-2020503676', 'TGS-2026064719')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ - Design Thinking Course for Businesses', 'CASL - Design Thinking Course for Businesses')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Per-SKU cms_blocks: rename identifiers + repoint content to the new SKU
UPDATE cms_block SET identifier = 'course_TGS-2026064719_brochure',
    title = REPLACE(title, 'TGS-2020503676', 'TGS-2026064719'),
    content = REPLACE(content, 'TGS-2020503676', 'TGS-2026064719')
  WHERE identifier = 'course_TGS-2020503676_brochure';
UPDATE cms_block SET identifier = 'course_TGS-2026064719_learning_outcomes',
    title = REPLACE(title, 'TGS-2020503676', 'TGS-2026064719'),
    content = REPLACE(content, 'TGS-2020503676', 'TGS-2026064719')
  WHERE identifier = 'course_TGS-2020503676_learning_outcomes';

-- Search-term redirects: repoint the old product URL to the new one (the
-- catalog_url reindex will also leave a 301, but search redirects should
-- land directly on the live URL, not chain through it)
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'tertiarycourses.com.sg/wsq-design-thinking-course-for-businesses.html', 'tertiarycourses.com.sg/casl-design-thinking-course-for-businesses.html')
  WHERE redirect LIKE '%tertiarycourses.com.sg/wsq-design-thinking-course-for-businesses.html%';
