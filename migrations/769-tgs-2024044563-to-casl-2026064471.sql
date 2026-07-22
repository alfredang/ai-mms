-- 769: Repurpose + re-register WSQ course
--   "WSQ - CompTIA PenTest+ Training" (TGS-2024044563)
--   -> "CASL - CompTIA PenTest+ Training" (TGS-2026064471)
-- The SKU CHANGES (new SSG registration). Content is retained — only the
-- name prefix, SKU references (funding/SFEC/SFC/PSEA links), URL, SEO meta,
-- labels, cover and per-SKU cms_block identifiers change.
-- Partner-safe: TGS- SKUs absent on MY/GH => @e NULL => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024044563');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- SKU re-registration (guarded: only when the new SKU is not already taken)
UPDATE catalog_product_entity SET sku = 'TGS-2026064471'
  WHERE entity_id = @e
    AND NOT EXISTS (SELECT 1 FROM (SELECT sku FROM catalog_product_entity WHERE sku = 'TGS-2026064471') x);

-- Name + labels + fresh cover (rendered with the CASL chip replacing WSQ)
UPDATE catalog_product_entity_varchar SET value = 'CASL - CompTIA PenTest+ Training'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064471-20260722-183008.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'CASL - CompTIA PenTest+ Training'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope (this course has store 0 + 1 rows)
UPDATE catalog_product_entity_varchar SET value = 'casl-comptia-pentest-training'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta (this course carries meta only at store 0 — no store filter needed)
UPDATE catalog_product_entity_varchar SET value = 'CASL CompTIA PenTest+ Exam Preparation Guide | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt;
UPDATE catalog_product_entity_varchar SET value = REPLACE(value, 'WSQ', 'CASL')
  WHERE entity_id = @e AND attribute_id = @a_md;

-- short_description: repoint every old TGS reference (SFEC / SFC / PSEA
-- funding links) to the new registration, and retitle old-name mentions
-- (brochure link text and titles).
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'TGS-2024044563', 'TGS-2026064471')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ - CompTIA PenTest+ Training', 'CASL - CompTIA PenTest+ Training')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Per-SKU cms_blocks: rename identifiers + repoint content to the new SKU
UPDATE cms_block SET identifier = 'course_TGS-2026064471_brochure',
    title = REPLACE(title, 'TGS-2024044563', 'TGS-2026064471'),
    content = REPLACE(content, 'TGS-2024044563', 'TGS-2026064471')
  WHERE identifier = 'course_TGS-2024044563_brochure';
UPDATE cms_block SET identifier = 'course_TGS-2026064471_certification',
    title = REPLACE(title, 'TGS-2024044563', 'TGS-2026064471'),
    content = REPLACE(content, 'TGS-2024044563', 'TGS-2026064471')
  WHERE identifier = 'course_TGS-2024044563_certification';
UPDATE cms_block SET identifier = 'course_TGS-2026064471_learning_outcomes',
    title = REPLACE(title, 'TGS-2024044563', 'TGS-2026064471'),
    content = REPLACE(content, 'TGS-2024044563', 'TGS-2026064471')
  WHERE identifier = 'course_TGS-2024044563_learning_outcomes';

-- Search-term redirects: remap rows pointing at the old wsq-…html URL (and
-- the older exam-prep URL that 301s into it) straight to the new casl-…html
-- URL so no 301 chain / redirect rot is left behind (755/762 precedent).
-- REPLACE on the full SG-domain URL — partner-safe.
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'https://www.tertiarycourses.com.sg/wsq-comptia-pentest-training.html', 'https://www.tertiarycourses.com.sg/casl-comptia-pentest-training.html')
  WHERE redirect LIKE '%wsq-comptia-pentest-training.html%';
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'https://www.tertiarycourses.com.sg/wsq-comptia-pentest-exam-prep.html', 'https://www.tertiarycourses.com.sg/casl-comptia-pentest-training.html')
  WHERE redirect LIKE '%wsq-comptia-pentest-exam-prep.html%';
