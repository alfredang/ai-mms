-- 922: Repurpose + re-register WSQ course
--   "WSQ - Data Analytics with Excel" (TGS-2022014978)
--   -> "CASL - Data Analytics with Excel" (TGS-2026064861)
-- The SKU CHANGES (new SSG registration). Content is retained — only the
-- name prefix, SKU references, URL (301 from the old slug), labels, cover,
-- per-SKU cms_block identifiers and the Funding Validity window change.
-- @e resolves via EITHER sku so the file stays idempotent after the flip.
-- Partner-safe: TGS- SKUs absent on MY/GH => @e NULL => guarded no-op;
-- rewrite/search statements are additionally guarded on the SG store.
--
-- short_description carries NO SKU references and no old-name mention (the
-- Certification / Skills Framework / Funding / Brochure sections were
-- extracted to cms_blocks by 885-890); its prose says "WSQ-endorsed course"
-- once, reworded below.

SET @e := (SELECT entity_id FROM catalog_product_entity
             WHERE sku IN ('TGS-2022014978', 'TGS-2026064861') LIMIT 1);
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_uk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_sd    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @fv_start := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'news_from_date');
SET @fv_end   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'news_to_date');

-- SKU re-registration (guarded: only when the new SKU is not already taken)
UPDATE catalog_product_entity SET sku = 'TGS-2026064861'
  WHERE entity_id = @e AND sku = 'TGS-2022014978'
    AND NOT EXISTS (SELECT 1 FROM (SELECT sku FROM catalog_product_entity WHERE sku = 'TGS-2026064861') x);

-- Name + labels (SET outright — the live name row carries a trailing space)
-- + fresh cover rendered with the CASL chip replacing WSQ
UPDATE catalog_product_entity_varchar SET value = 'CASL - Data Analytics with Excel'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2026064861-20260811-180758.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label (store 0 + 1 rows)
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'CASL - Data Analytics with Excel'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope so the URL Rewrites indexer
-- regenerates cleanly.
UPDATE catalog_product_entity_varchar SET value = 'casl-data-analytics-with-excel'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta (stores 0 + 1 both carry overrides). meta_title must be the plain
-- title — MMD_Seotitle prepends the funding prefix and appends the brand at
-- render time; the baked "WSQ … | Tertiary Courses Singapore" is the exact
-- anti-pattern migration 853 cleaned up.
UPDATE catalog_product_entity_varchar SET value = 'Data Analytics with Excel Training'
  WHERE entity_id = @e AND attribute_id = @a_mt;
UPDATE catalog_product_entity_varchar
  SET value = REPLACE(REPLACE(value, 'WSQ-endorsed', 'SkillsFuture-funded'),
              'WSQ funding subsidy', 'SkillsFuture funding subsidy')
  WHERE entity_id = @e AND attribute_id = @a_md;
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ Funding,', 'CASL Funding,')
  WHERE entity_id = @e AND attribute_id = @a_mk;

-- short_description prose: reword the single "WSQ-endorsed course" mention.
UPDATE catalog_product_entity_text SET value = REPLACE(value, 'WSQ-endorsed', 'SkillsFuture-funded')
  WHERE entity_id = @e AND attribute_id = @a_sd;

-- Per-SKU cms_blocks: rename identifiers + repoint title/content to the new
-- SKU and name. This course carries all five: _brochure, _learning_outcomes,
-- _certification, _skills_framework, _funding_and_grant (the last is retired
-- from TGS- rendering since 891 but kept consistent as data).
UPDATE cms_block SET identifier = REPLACE(identifier, 'TGS-2022014978', 'TGS-2026064861'),
    title   = REPLACE(title, 'TGS-2022014978', 'TGS-2026064861'),
    content = REPLACE(REPLACE(content, 'TGS-2022014978', 'TGS-2026064861'),
              'WSQ - Data Analytics with Excel',
              'CASL - Data Analytics with Excel'),
    update_time = NOW()
  WHERE identifier LIKE 'course\_TGS-2022014978\_%';

-- Funding Validity window for the new registration (TPG: Valid From
-- 09-08-2026, Valid To 08-08-2027), replacing the expired old-SKU window
-- (2022-08-09 -> 2026-08-08).
INSERT INTO catalog_product_entity_datetime (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @fv_start, 0, @e, '2026-08-09 00:00:00' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = '2026-08-09 00:00:00';
INSERT INTO catalog_product_entity_datetime (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @fv_end, 0, @e, '2027-08-08 00:00:00' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = '2027-08-08 00:00:00';

-- 301 the old slug at the new one: repoint the existing rewrite row (the
-- system row still holds the old request_path until reindex) and force it
-- permanent + manual; create the row where none exists (both scopes).
UPDATE core_url_rewrite
  SET target_path = 'casl-data-analytics-with-excel.html',
      options = 'RP', is_system = 0
  WHERE @sg = 1 AND @e IS NOT NULL
    AND request_path = 'wsq-data-analytics-with-excel.html'
    AND store_id IN (0, 1);
INSERT IGNORE INTO core_url_rewrite
  (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id,
       CONCAT('manual-301-', MD5('wsq-data-analytics-with-excel.html'), '-', s.store_id),
       'wsq-data-analytics-with-excel.html',
       'casl-data-analytics-with-excel.html', 0, 'RP'
FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
WHERE @sg = 1 AND @e IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x
                  WHERE x.request_path = 'wsq-data-analytics-with-excel.html'
                    AND x.store_id = s.store_id);

-- Legacy alias rewrites that 301 INTO the old bare slug (e.g.
-- data-analytics-with-excel.html, power-bi-business-analytics-training-816.html,
-- raspberry-pi-iot-with-power-bi.html) — repoint straight at the new slug so
-- inbound links take one hop, not a chain.
UPDATE core_url_rewrite
  SET target_path = 'casl-data-analytics-with-excel.html'
  WHERE @sg = 1 AND @e IS NOT NULL
    AND target_path = 'wsq-data-analytics-with-excel.html'
    AND request_path <> 'wsq-data-analytics-with-excel.html';

-- Search-term redirects: ~80 SG rows point at the old URL (incl. the bare
-- old course code). REPLACE on the full SG-domain URL — partner-safe.
UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'https://www.tertiarycourses.com.sg/wsq-data-analytics-with-excel.html', 'https://www.tertiarycourses.com.sg/casl-data-analytics-with-excel.html')
  WHERE redirect LIKE '%wsq-data-analytics-with-excel.html%';
UPDATE catalogsearch_query
  SET redirect = 'https://www.tertiarycourses.com.sg/casl-data-analytics-with-excel.html'
  WHERE @sg = 1 AND query_text IN ('TGS-2022014978', 'TGS-2026064861');
