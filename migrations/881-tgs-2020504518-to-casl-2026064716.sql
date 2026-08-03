-- 881: Repurpose + re-register WSQ course
--   "WSQ - Business Innovation with Artificial Intelligence" (TGS-2020504518)
--   -> "CASL - Business Innovation with Artificial Intelligence" (TGS-2026064716)
-- The SKU CHANGES (new SSG registration). Content is retained — only the
-- name prefix, SKU references (funding/SFEC/SFC/PSEA links), URL, labels,
-- cover, per-SKU cms_block identifiers and the Funding Validity window
-- change. NOTE: the SKU itself was already flipped in the admin on SG prod,
-- so @e is resolved via EITHER sku and the sku UPDATE is a guarded no-op
-- there; on a fresh/older DB it performs the flip.
-- Partner-safe: TGS- SKUs absent on MY/GH => @e NULL => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity
             WHERE sku IN ('TGS-2020504518', 'TGS-2026064716') LIMIT 1);

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @fv_start := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'news_from_date');
SET @fv_end   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'news_to_date');

-- SKU re-registration (guarded: only when the new SKU is not already taken)
UPDATE catalog_product_entity SET sku = 'TGS-2026064716'
  WHERE entity_id = @e AND sku = 'TGS-2020504518'
    AND NOT EXISTS (SELECT 1 FROM (SELECT sku FROM catalog_product_entity WHERE sku = 'TGS-2026064716') x);

-- Name + labels + fresh cover (rendered with the CASL chip replacing WSQ)
UPDATE catalog_product_entity_varchar SET value = 'CASL - Business Innovation with Artificial Intelligence'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064716-20260803-134959.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'CASL - Business Innovation with Artificial Intelligence'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope (this course has store 0 + 1 rows).
-- No meta_title/meta_description to touch (both NULL — MMD_Seotitle composes at render).
UPDATE catalog_product_entity_varchar SET value = 'casl-business-innovation-with-artificial-intelligence'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- short_description: repoint every old TGS reference (SFEC / SFC / PSEA
-- funding links, 2 occurrences) to the new registration, and retitle
-- old-name mentions (brochure link title + text, 2 occurrences).
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'TGS-2020504518', 'TGS-2026064716')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ - Business Innovation with Artificial Intelligence', 'CASL - Business Innovation with Artificial Intelligence')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Per-SKU cms_blocks: rename identifiers + repoint content to the new SKU
-- (this course carries _brochure + _learning_outcomes only)
UPDATE cms_block SET identifier = 'course_TGS-2026064716_brochure',
    title = REPLACE(title, 'TGS-2020504518', 'TGS-2026064716'),
    content = REPLACE(content, 'TGS-2020504518', 'TGS-2026064716')
  WHERE identifier = 'course_TGS-2020504518_brochure';
UPDATE cms_block SET identifier = 'course_TGS-2026064716_learning_outcomes',
    title = REPLACE(title, 'TGS-2020504518', 'TGS-2026064716'),
    content = REPLACE(content, 'TGS-2020504518', 'TGS-2026064716')
  WHERE identifier = 'course_TGS-2020504518_learning_outcomes';

-- Funding Validity window (SSG TPG master list: Valid From 5 Aug 2026,
-- Valid To 4 Aug 2027). Migration 876 carried these dates for the NEW SKU
-- but ran before the admin SKU flip, so they never landed — re-key here.
-- Rendered by the storefront "Funding Validity" card (view.phtml 6b).
INSERT INTO catalog_product_entity_datetime (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @fv_start, 0, @e, '2026-08-05 00:00:00' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = '2026-08-05 00:00:00';
INSERT INTO catalog_product_entity_datetime (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @fv_end, 0, @e, '2027-08-04 00:00:00' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = '2027-08-04 00:00:00';

-- Search-term redirects: remap every row pointing at the old wsq-…html URL
-- (30 rows on SG prod) straight to the new casl-…html URL so no 301 chain /
-- redirect rot is left behind. REPLACE on the full SG-domain URL — partner-safe.
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'https://www.tertiarycourses.com.sg/wsq-business-innovation-with-artificial-intelligence.html', 'https://www.tertiarycourses.com.sg/casl-business-innovation-with-artificial-intelligence.html')
  WHERE redirect LIKE '%wsq-business-innovation-with-artificial-intelligence.html%';

-- The bare old-course-code query currently bounces to the generic
-- wsq-artificial-intelligence.html listing — point it (and searches for the
-- new code, if any exist) at the course page itself.
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/casl-business-innovation-with-artificial-intelligence.html'
  WHERE query_text IN ('TGS-2020504518', 'TGS-2026064716');
