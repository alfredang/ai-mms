-- 841: Repurpose C469 "Tableau Desktop Intermediate Training" -> "Tableau Desktop Masterclass"
-- Same-subject rename: topics (description) unchanged; short_description intro rewritten via
-- CONCAT/SUBSTRING splice so the Certificate + Funding sections stay byte-identical per store.
-- Partner-safe: every statement guarded on @e; no funding content added or removed here.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C469' LIMIT 1);

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_title');
SET @a_md   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'meta_description');
SET @a_uk   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_key');
SET @a_up   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'url_path');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'thumbnail_label');
SET @a_ciu  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'course_image_url');
SET @a_sd   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'short_description');

-- Store-0 varchar attributes
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_name, 0, @e, 'Tableau Desktop Masterclass' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_mt, 0, @e, 'Tableau Desktop Masterclass | Tertiary Courses Singapore' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_md, 0, @e, 'Master Tableau Desktop from fundamentals to advanced analytics: dashboards, calculated fields, LOD expressions, forecasting, clustering and map analytics in this hands-on masterclass.' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_uk, 0, @e, 'tableau-desktop-masterclass' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_il, 0, @e, 'Tableau Desktop Masterclass' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_sil, 0, @e, 'Tableau Desktop Masterclass' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_til, 0, @e, 'Tableau Desktop Masterclass' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etid, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C469-20260729-015323.png' FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- url_path: delete at EVERY scope; the Catalog URL Rewrites indexer regenerates it
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up AND @e IS NOT NULL;

-- Clear partner/store-scoped overrides for the renamed varchar attrs so store 0 wins (GH shadow fix)
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND store_id <> 0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_uk, @a_il, @a_sil, @a_til, @a_ciu) AND @e IS NOT NULL;

-- short_description: swap ONLY the intro paragraphs; splice the Certificate + Funding tail
-- byte-identically. Applies to every store row that has the standard Certificate heading,
-- so partner store-scoped overrides (if any) get the same intro without touching their tail.
UPDATE catalog_product_entity_text
SET value = CONCAT('<p>Master the full power of Tableau with the Tableau Desktop Masterclass. This hands-on masterclass takes you from Tableau fundamentals to advanced analytics &mdash; explore the Tableau interface, work with dimensions and measures, connect to diverse data sources, and build compelling views with data joins, blending and aggregations.</p>\n<p>Go beyond the basics with data transformation, interactive dashboards and stories, calculated fields and parameters, and advanced analytics including trend lines, forecasting, clustering and Level of Detail (LOD) expressions. Round off with map analytics using map services and Mapbox integration. With hands-on exercises and expert-led content, you will leave able to turn raw data into compelling visual narratives with Tableau Desktop.</p>\n', SUBSTRING(value, LOCATE('<h2>Certificate</h2>', value)))
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_sd AND LOCATE('<h2>Certificate</h2>', value) > 0;

-- Media gallery per-image label (zoom gallery renders this as img title/alt)
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Tableau Desktop Masterclass'
WHERE g.entity_id = @e AND @e IS NOT NULL;
