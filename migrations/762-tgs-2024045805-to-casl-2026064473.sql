-- 762: Repurpose + re-register WSQ course
--   "WSQ - Create Social Media Campaigns with Agentic AI" (TGS-2024045805)
--   -> "CASL - Create Social Media Campaigns with Agentic AI" (TGS-2026064473)
-- The SKU CHANGES (new SSG registration). Content is retained — only the
-- name prefix, SKU references (funding/SFEC/SFC/PSEA links), URL, SEO meta,
-- labels, cover, per-SKU cms_block identifiers and the search-term redirects
-- change. Also fixes the brochure host (ai-mms.tertiaryinfo.tech drops the
-- /media prefix on redirect -> 404; 761 precedent).
-- Partner-safe: TGS- SKUs absent on MY/GH => @e NULL => guarded no-op; the
-- redirect REPLACE matches the SG domain only.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024045805');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- SKU re-registration (guarded: only when the new SKU is not already taken)
UPDATE catalog_product_entity SET sku = 'TGS-2026064473'
  WHERE entity_id = @e
    AND NOT EXISTS (SELECT 1 FROM (SELECT sku FROM catalog_product_entity WHERE sku = 'TGS-2026064473') x);

-- Name + labels + fresh cover (rendered with the CASL chip replacing WSQ)
UPDATE catalog_product_entity_varchar SET value = 'CASL - Create Social Media Campaigns with Agentic AI'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064473-20260722-182620.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'CASL - Create Social Media Campaigns with Agentic AI'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope (this course has store 0 + 1 rows)
UPDATE catalog_product_entity_varchar SET value = 'casl-create-social-media-campaigns-with-agentic-ai'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta (meta_title exists at store 0 only on this course)
UPDATE catalog_product_entity_varchar SET value = REPLACE(value, 'WSQ', 'CASL')
  WHERE entity_id = @e AND attribute_id = @a_mt;

-- short_description: repoint every old TGS reference (SFEC / SFC / PSEA
-- funding links + "course code" text) to the new registration, and retitle
-- old-name mentions (brochure link title + text — the link TEXT carries a
-- double space after "WSQ - ", so both shapes are replaced).
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'TGS-2024045805', 'TGS-2026064473')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ -  Create Social Media Campaigns with Agentic AI', 'CASL - Create Social Media Campaigns with Agentic AI')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ - Create Social Media Campaigns with Agentic AI', 'CASL - Create Social Media Campaigns with Agentic AI')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Per-SKU cms_blocks: rename identifiers + repoint content to the new SKU;
-- brochure link also moves off the ai-mms.tertiaryinfo.tech host (404 trap).
UPDATE cms_block SET identifier = 'course_TGS-2026064473_brochure',
    title = REPLACE(title, 'TGS-2024045805', 'TGS-2026064473'),
    content = REPLACE(REPLACE(content, 'TGS-2024045805', 'TGS-2026064473'),
                      'https://ai-mms.tertiaryinfo.tech/media/', 'https://www.tertiarycourses.com.sg/media/')
  WHERE identifier = 'course_TGS-2024045805_brochure';
UPDATE cms_block SET identifier = 'course_TGS-2026064473_learning_outcomes',
    title = REPLACE(title, 'TGS-2024045805', 'TGS-2026064473')
  WHERE identifier = 'course_TGS-2024045805_learning_outcomes';

-- Search-term redirects: 15 queries point at the old WSQ URL — remap them to
-- the new CASL URL so they don't rot into a 301 chain / 404.
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect,
    'wsq-create-social-media-campaigns-with-agentic-ai.html',
    'casl-create-social-media-campaigns-with-agentic-ai.html')
  WHERE redirect LIKE '%tertiarycourses.com.sg/wsq-create-social-media-campaigns-with-agentic-ai.html%';
