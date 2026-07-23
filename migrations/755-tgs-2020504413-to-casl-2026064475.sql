-- 755: Repurpose + re-register WSQ course
--   "WSQ - Data Analytics and Visualization with R" (TGS-2020504413)
--   -> "CASL - Data Analytics and Visualization with R" (TGS-2026064475)
-- The SKU CHANGES (new SSG registration). Content is retained — only the
-- name prefix, SKU references (funding/SFEC/SFC/PSEA links), URL, SEO meta,
-- labels, cover, per-SKU cms_block identifiers and the search-term redirects
-- change.
-- Partner-safe: TGS- SKUs absent on MY/GH => @e NULL => guarded no-op; the
-- redirect REPLACE matches the SG domain only.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020504413');

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
UPDATE catalog_product_entity SET sku = 'TGS-2026064475'
  WHERE entity_id = @e
    AND NOT EXISTS (SELECT 1 FROM (SELECT sku FROM catalog_product_entity WHERE sku = 'TGS-2026064475') x);

-- Name + labels + fresh cover (rendered with the CASL chip replacing WSQ)
UPDATE catalog_product_entity_varchar SET value = 'CASL - Data Analytics and Visualization with R'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064475-20260722-181803.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label (old labels said "Data Analysis")
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'CASL - Data Analytics and Visualization with R'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope (store 1 carries one too)
UPDATE catalog_product_entity_varchar SET value = 'casl-data-analytics-and-visualization-with-r'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta
UPDATE catalog_product_entity_varchar SET value = 'CASL Data Analytics and Visualization with R - Transform Your Data Skills | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt;
UPDATE catalog_product_entity_varchar SET value = REPLACE(REPLACE(value, 'WSQ-accredited course', 'CASL-accredited course'), 'WSQ funding subsidy', 'CASL funding subsidy')
  WHERE entity_id = @e AND attribute_id = @a_md;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ', 'CASL')
  WHERE entity_id = @e AND attribute_id = @a_mk;

-- short_description: repoint every old TGS reference (SFEC / SFC / PSEA
-- funding links) to the new registration, and retitle old-name mentions
-- (intro copy + brochure link text and titles).
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'TGS-2020504413', 'TGS-2026064475')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ - Data Analytics and Visualization with R', 'CASL - Data Analytics and Visualization with R')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ-endorsed course in Data Analytics and Visualization with R', 'CASL-endorsed course in Data Analytics and Visualization with R')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Per-SKU cms_blocks: rename identifiers + repoint content to the new SKU
-- (brochure block links media/courses/brochures/TGS-2026064475-SG.pdf — the
-- PDF is copied alongside on the prod media volume).
UPDATE cms_block SET identifier = 'course_TGS-2026064475_brochure',
    title = REPLACE(title, 'TGS-2020504413', 'TGS-2026064475'),
    content = REPLACE(content, 'TGS-2020504413', 'TGS-2026064475')
  WHERE identifier = 'course_TGS-2020504413_brochure';
UPDATE cms_block SET identifier = 'course_TGS-2026064475_learning_outcomes',
    title = REPLACE(title, 'TGS-2020504413', 'TGS-2026064475'),
    content = REPLACE(content, 'TGS-2020504413', 'TGS-2026064475')
  WHERE identifier = 'course_TGS-2020504413_learning_outcomes';

-- Search-term redirects: 20 queries point at the old WSQ URL — remap them to
-- the new CASL URL so they don't ride a 301 chain (SG-domain match only).
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect,
    'tertiarycourses.com.sg/wsq-data-analytics-and-visualization-with-r.html',
    'tertiarycourses.com.sg/casl-data-analytics-and-visualization-with-r.html')
  WHERE redirect LIKE '%tertiarycourses.com.sg/wsq-data-analytics-and-visualization-with-r.html%';
