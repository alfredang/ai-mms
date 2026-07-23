-- 712: Repurpose WSQ course TGS-2020505996
--   "WSQ - Mastering Facebook Social Media Marketing for High-Impact Lead Generation"
--   -> "WSQ - Agentic AI for Social Media Marketing"
-- Title-led rebrand: the supplied LOs / outline / About matched the course's
-- CURRENT content exactly, so description, short_description intro and the
-- learning-outcomes block are left as-is. Changes: name, labels, url_key,
-- meta, cover, gallery label, brochure link. Trainer bios have no title quotes.
-- SG-only in effect: TGS- SKUs absent on partner sites => guarded no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020505996');

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

-- Name + labels + cover
UPDATE catalog_product_entity_varchar SET value = 'WSQ - Agentic AI for Social Media Marketing'
  WHERE entity_id = @e AND attribute_id IN (@a_name, @a_il, @a_sil, @a_til) AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/TGS-2020505996-20260722-170530.png'
  WHERE entity_id = @e AND attribute_id = @a_ciu AND store_id = 0;

-- Media-gallery per-image label
UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
  SET gv.label = 'WSQ - Agentic AI for Social Media Marketing'
  WHERE g.entity_id = @e;

-- URL: new url_key; drop url_path at EVERY scope
UPDATE catalog_product_entity_varchar SET value = 'wsq-agentic-ai-for-social-media-marketing'
  WHERE entity_id = @e AND attribute_id = @a_uk AND store_id = 0;
DELETE FROM catalog_product_entity_varchar WHERE entity_id = @e AND attribute_id = @a_up;

-- SEO meta
UPDATE catalog_product_entity_varchar SET value = 'WSQ Agentic AI for Social Media Marketing | Tertiary Courses Singapore'
  WHERE entity_id = @e AND attribute_id = @a_mt AND store_id = 0;
UPDATE catalog_product_entity_varchar SET value = 'Plan, run, and optimise social media marketing campaigns with Facebook Ads, audience insights, and performance analytics. Enjoy up to 70% WSQ funding subsidy.'
  WHERE entity_id = @e AND attribute_id = @a_md AND store_id = 0;
UPDATE catalog_product_entity_text SET value = 'WSQ social media marketing course, agentic AI marketing, Facebook Ads course Singapore, social media campaign planning, Facebook Pixel analytics, ad retargeting, social media community management, AI marketing automation'
  WHERE entity_id = @e AND attribute_id = @a_mk AND store_id = 0;

-- Brochure anchor: stale Drive link with old title -> on-site generated PDF
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'https://drive.google.com/file/d/1jf57ZHGGyJFYi1-eFqEohZzWxLRMZLIM/view?usp=sharing', 'https://www.tertiarycourses.com.sg/media/courses/brochures/TGS-2020505996-SG.pdf')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'WSQ - Mastering Facebook Social Media Marketing for High-Impact Lead Generation', 'WSQ - Agentic AI for Social Media Marketing')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
