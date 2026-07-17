-- Repurpose course C156 from "Visual Magic with Canva: Design Like a Pro" to
-- "Canva Design Masterclass" (rebrand: name, overview, meta, url_key, image labels).
-- The 1-day / 6-topic curriculum (description), price ($350) and
-- duration (7.5h) are intentionally kept.
-- Funding section stays in cms_block course_C156_funding_and_grant (untouched).
-- Cover image intentionally kept (regenerate via the cover dialog later).
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C156.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C156');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Canva Design Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Design like a pro in this hands-on 1-day Canva Design Masterclass. Canva is the world&rsquo;s most popular online design platform, trusted by millions to create stunning graphics, social media posts and professional branding materials without expensive software or a steep learning curve. Starting from Canva&rsquo;s interface and core design principles&mdash;typography, layout and visual communication&mdash;you will master colour theory, forms and shapes, then move into storyboarding and flow design for structured visual projects.</p>
<p>The masterclass then focuses on professional polish: applying design best practices, analysing aesthetics and user experience, critiquing and enhancing existing designs, and exploring Canva&rsquo;s advanced features for innovative design strategies. Through practical exercises, case studies and group projects, you will build a portfolio of real designs as you learn. By the end of the course, you will be able to confidently produce visually compelling designs that elevate your brand and captivate your audience.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Canva Design Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master graphic design with Canva in this hands-on 1-day masterclass. Create stunning graphics, social media posts and branding materials at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Canva, Canva Design Masterclass, Graphic Design, Visual Design, Social Media Design, Branding, Colour Theory, Typography, Storyboarding, Visual Communication, Tertiary Courses, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'canva-design-masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Canva Design Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Canva Design Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Canva Design Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_mk);

-- Stale url_path rows point at the old visual-magic-with-canva URL;
-- drop them at every scope so the Catalog URL Rewrites indexer regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND attribute_id=@a_up AND @a_up IS NOT NULL;
