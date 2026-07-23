-- 766: Repurpose + re-register WSQ course
--   "WSQ - Hands-On Web App Development with Javascript" (TGS-2020504192)
--   -> "CASL - Hands-On Web App Development with Javascript" (TGS-2026064472)
-- The SKU CHANGES (new SSG registration). Content is retained — only the
-- name prefix, SKU references (SFEC/SFC/PSEA funding links), URL, SEO meta,
-- labels, cover, per-SKU cms_block identifiers and search-term redirects
-- change. Also removes the OpenCerts bullet (CASL courses do not award
-- OpenCerts; this course's bullet has CRLF line endings and a single space
-- in "have achieved").
-- Partner-safe: TGS- SKUs absent on MY/GH => @e NULL => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020504192');

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
UPDATE catalog_product_entity SET sku = 'TGS-2026064472'
  WHERE entity_id = @e
    AND NOT EXISTS (SELECT 1 FROM (SELECT sku FROM catalog_product_entity WHERE sku = 'TGS-2026064472') x);

-- Name + labels + fresh cover (rendered with the CASL chip replacing WSQ)
UPDATE catalog_product_entity_varchar SET value = 'CASL - Hands-On Web App Development with Javascript'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064472-20260722-182835.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'CASL - Hands-On Web App Development with Javascript'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope (store 0 AND 1 rows exist)
UPDATE catalog_product_entity_varchar SET value = 'casl-hands-on-web-app-development-with-javascript'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta
UPDATE catalog_product_entity_varchar SET value = REPLACE(value, 'WSQ Javascript Programming', 'CASL Javascript Programming')
  WHERE entity_id = @e AND attribute_id = @a_mt;
UPDATE catalog_product_entity_varchar SET value = REPLACE(value, 'WSQ funding subsidy', 'CASL funding subsidy')
  WHERE entity_id = @e AND attribute_id = @a_md;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ', 'CASL')
  WHERE entity_id = @e AND attribute_id = @a_mk;

-- short_description: repoint every old TGS reference (SFEC / SFC / PSEA
-- funding links + "course code:" text) to the new registration, and retitle
-- the old-name mentions (brochure link title + anchor text).
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'TGS-2020504192', 'TGS-2026064472')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ - Hands-On Web App Development with Javascript', 'CASL - Hands-On Web App Development with Javascript')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- CASL rule: no OpenCerts. This course's bullet is the CRLF single-space
-- variant; match the \n shape too, belt-and-braces.
UPDATE catalog_product_entity_text SET value = REPLACE(value, '<li>\r\n<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</p>\r\n</li>\r\n', '')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, '<li>\n<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</p>\n</li>\n', '')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Per-SKU cms_blocks: rename identifiers + repoint content to the new SKU,
-- and fix the brochure host (ai-mms.tertiaryinfo.tech redirect drops /media
-- -> 404; serve from the SG domain — 761 precedent). The PDF itself is
-- regenerated at the new SKU filename on the prod media volume.
UPDATE cms_block SET identifier = 'course_TGS-2026064472_brochure',
    title = REPLACE(title, 'TGS-2020504192', 'TGS-2026064472'),
    content = REPLACE(REPLACE(content, 'TGS-2020504192', 'TGS-2026064472'), 'https://ai-mms.tertiaryinfo.tech/media/', 'https://www.tertiarycourses.com.sg/media/')
  WHERE identifier = 'course_TGS-2020504192_brochure';
UPDATE cms_block SET identifier = 'course_TGS-2026064472_learning_outcomes',
    title = REPLACE(title, 'TGS-2020504192', 'TGS-2026064472'),
    content = REPLACE(content, 'TGS-2020504192', 'TGS-2026064472')
  WHERE identifier = 'course_TGS-2020504192_learning_outcomes';

-- Search-term redirects: repoint the ~22 stored redirects at the old URL to
-- the new one so they don't 301-chain (SG-only data; no-op on partners).
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, '/wsq-hands-on-web-app-development-with-javascript.html', '/casl-hands-on-web-app-development-with-javascript.html')
  WHERE redirect LIKE '%/wsq-hands-on-web-app-development-with-javascript.html';
