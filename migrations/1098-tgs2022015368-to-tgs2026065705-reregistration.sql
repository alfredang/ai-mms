-- 1098: SSG re-registration of "WSQ - 3D Modelling with Blender for Beginners"
--   TGS-2022015368  ->  TGS-2026065705
--   Funding Validity: 24-08-2026 -> 29-08-2027
--
-- This is a RE-REGISTRATION, not a rename or repurpose. Probed on SG prod
-- (entity_id 1283) before writing: the course NAME, url_key, all ~60 url
-- rewrites, the cover art, meta_description, description and
-- short_description are all correct and topic-accurate already, so this file
-- deliberately does NOT touch them. Only the SKU, the five per-SKU cms_block
-- identifiers, the funding-validity window and the two course-code search
-- rows change.
--
-- short_description on prod already byte-matches the supplied "About This
-- Course" copy (two <p> paragraphs, no SKU reference, no old-code mention),
-- so no content rewrite is needed or performed.
--
-- @e resolves via EITHER sku so the file stays idempotent after the flip.
-- Partner-safe: TGS- SKUs do not exist on MY/GH => @e NULL => every statement
-- guarded to a no-op there; the search/rewrite statements additionally gate on
-- the SG store. See memory feedback_sku_migrations_hit_partners_irreversibly.
--
-- NOTE (manual, out-of-band): the brochure PDF is resolved FILESYSTEM-FIRST by
-- view.phtml from the LIVE sku (media/courses/brochures/<sku>-SG.pdf), so the
-- file must be copied to TGS-2026065705-SG.pdf on the media volume or the
-- Download Course Brochure CTA falls back to the stale old-SKU URL. Done on
-- prod alongside this migration; media/ is a volume, not baked into the image.

SET @e  := (SELECT entity_id FROM catalog_product_entity
              WHERE sku IN ('TGS-2022015368', 'TGS-2026065705') LIMIT 1);
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @fv_start := (SELECT attribute_id FROM eav_attribute
                    WHERE entity_type_id = 4 AND attribute_code = 'news_from_date');
SET @fv_end   := (SELECT attribute_id FROM eav_attribute
                    WHERE entity_type_id = 4 AND attribute_code = 'news_to_date');

-- (1) SKU re-registration. Guarded so it only fires while the row still
-- carries the old code and the new code is not already taken elsewhere.
UPDATE catalog_product_entity SET sku = 'TGS-2026065705'
  WHERE entity_id = @e AND sku = 'TGS-2022015368'
    AND NOT EXISTS (SELECT 1 FROM (SELECT sku FROM catalog_product_entity
                                     WHERE sku = 'TGS-2026065705') x);

-- (2) Per-SKU cms_blocks. view.phtml builds each section's identifier as
-- 'course_<LIVE sku>_<code>' ($_courseSectionHtml), so these MUST move with
-- the SKU or the Brochure / Learning Outcomes / Certification / Skills
-- Framework / Funding cards all render blank on the product page.
-- content REPLACE also repoints the brochure href at the new-SKU filename.
UPDATE cms_block
   SET identifier  = REPLACE(identifier, 'TGS-2022015368', 'TGS-2026065705'),
       title       = REPLACE(title,      'TGS-2022015368', 'TGS-2026065705'),
       content     = REPLACE(content,    'TGS-2022015368', 'TGS-2026065705'),
       update_time = NOW()
 WHERE identifier LIKE 'course\_TGS-2022015368\_%';

-- (3) Funding Validity window for the new registration (24-08-2026 ->
-- 29-08-2027), replacing the expiring old-SKU window (2022-08-30 ->
-- 2026-08-29). On TGS- SKUs news_from_date/news_to_date carry SSG funding
-- validity, NOT class dates -- see memory
-- project_funding_validity_news_dates_dual_semantics.
INSERT INTO catalog_product_entity_datetime (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @fv_start, 0, @e, '2026-08-24 00:00:00' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = '2026-08-24 00:00:00';
INSERT INTO catalog_product_entity_datetime (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @fv_end, 0, @e, '2027-08-29 00:00:00' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = '2027-08-29 00:00:00';

-- (4) Course-code search rows. The old-code row (query_id 58269) pointed at
-- the legacy alias wsq-3d-modeling-with-blender.html; retarget both codes at
-- the real live slug so a learner searching either code lands in one hop.
UPDATE catalogsearch_query
   SET redirect = 'https://www.tertiarycourses.com.sg/wsq-3d-modelling-with-blender-for-beginners.html',
       num_results = 1, is_processed = 1
 WHERE @sg = 1 AND store_id = 1
   AND query_text IN ('TGS-2022015368', 'TGS-2026065705');

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'TGS-2026065705', 1, 1, 0,
       'https://www.tertiarycourses.com.sg/wsq-3d-modelling-with-blender-for-beginners.html', 1
  FROM dual
 WHERE @sg = 1 AND @e IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM (SELECT query_id FROM catalogsearch_query
                                    WHERE query_text = 'TGS-2026065705' AND store_id = 1) y);
