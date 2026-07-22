-- 753: Repurpose + re-register WSQ course
--   "WSQ - Cyber Security Awareness Course for Personal and Businesses" (TGS-2020503626)
--   -> "CASL - Cyber Security Awareness Course for Personal and Businesses" (TGS-2026064533)
-- The SKU CHANGES (new SSG registration). Content is retained — only the
-- name prefix, SKU references (SFEC/SFC funding links), URL, SEO meta,
-- labels, cover, per-SKU cms_block identifiers and search-term redirects
-- change. Also removes the OpenCerts bullet (CASL courses do not award
-- OpenCerts; this course's bullet variant carries a double &nbsp;).
-- Partner-safe: TGS- SKUs absent on MY/GH => @e NULL => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020503626');

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
UPDATE catalog_product_entity SET sku = 'TGS-2026064533'
  WHERE entity_id = @e
    AND NOT EXISTS (SELECT 1 FROM (SELECT sku FROM catalog_product_entity WHERE sku = 'TGS-2026064533') x);

-- Name + labels + fresh cover (rendered with the CASL chip replacing WSQ)
UPDATE catalog_product_entity_varchar SET value = 'CASL - Cyber Security Awareness Course for Personal and Businesses'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064533-20260722-181743.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label (old label had no dash: "WSQ Cyber Security ...")
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'CASL - Cyber Security Awareness Course for Personal and Businesses'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope
UPDATE catalog_product_entity_varchar SET value = 'casl-cyber-security-awareness-course-for-personal-and-businesses'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta (store_id=1 override rows exist but are NULL — REPLACE(NULL)=NULL is harmless)
UPDATE catalog_product_entity_varchar SET value = REPLACE(value, 'WSQ Cyber Security Awareness', 'CASL Cyber Security Awareness')
  WHERE entity_id = @e AND attribute_id = @a_mt;
UPDATE catalog_product_entity_varchar SET value = REPLACE(REPLACE(value, 'WSQ Cyber Security Awareness Course', 'CASL Cyber Security Awareness Course'), 'WSQ funding subsidy', 'CASL funding subsidy')
  WHERE entity_id = @e AND attribute_id = @a_md;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ', 'CASL')
  WHERE entity_id = @e AND attribute_id = @a_mk;

-- short_description: repoint every old TGS reference (SFEC / SFC funding
-- links) to the new registration, retitle old-name mentions (brochure link
-- text + title), and rebrand the intro "WSQ's ..." phrasing.
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'TGS-2020503626', 'TGS-2026064533')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ - Cyber Security Awareness Course for Personal and Businesses', 'CASL - Cyber Security Awareness Course for Personal and Businesses')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'with WSQ''s Cyber Security Awareness Course', 'with the CASL Cyber Security Awareness Course')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- CASL rule: no OpenCerts. This course's bullet variant has a double &nbsp;
-- ("have&nbsp;&nbsp;achieved") and CRLF line endings — remove it exactly.
UPDATE catalog_product_entity_text SET value = REPLACE(value, '<li>\r\n<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have&nbsp;&nbsp;achieved the Competency Standard(s) in the above Skills Framework.</p>\r\n</li>\r\n', '')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;

-- Per-SKU cms_blocks: rename identifiers + repoint content to the new SKU
-- (brochure block links media/courses/brochures/TGS-2026064533-SG.pdf — the
-- PDF is regenerated alongside on the prod media volume).
UPDATE cms_block SET identifier = 'course_TGS-2026064533_brochure',
    title = REPLACE(title, 'TGS-2020503626', 'TGS-2026064533'),
    content = REPLACE(content, 'TGS-2020503626', 'TGS-2026064533')
  WHERE identifier = 'course_TGS-2020503626_brochure';
UPDATE cms_block SET identifier = 'course_TGS-2026064533_learning_outcomes',
    title = REPLACE(title, 'TGS-2020503626', 'TGS-2026064533'),
    content = REPLACE(content, 'TGS-2020503626', 'TGS-2026064533')
  WHERE identifier = 'course_TGS-2020503626_learning_outcomes';

-- Search-term redirects: repoint the ~50 stored redirects at the old URL to
-- the new one so they don't 301-chain (SG-only data; no-op on partners).
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, '/wsq-cyber-security-awareness-course-for-personal-and-businesses.html', '/casl-cyber-security-awareness-course-for-personal-and-businesses.html')
  WHERE redirect LIKE '%/wsq-cyber-security-awareness-course-for-personal-and-businesses.html';
