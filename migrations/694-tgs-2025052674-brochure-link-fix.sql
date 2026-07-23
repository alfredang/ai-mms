-- 694: TGS-2025052674 follow-up — the short_description "Course Brochure"
-- section kept a Google Drive link titled with the OLD course name
-- (Fast-Track to Unreal ...). Point it at the regenerated on-site brochure
-- PDF and retitle to the new course name.
-- Partner-safe: TGS- SKU absent on MY/GH => @e NULL => no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025052674');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'https://drive.google.com/file/d/1Yss-99EUjESA5LgxPMKn3AwBG8GUd0BR/view?usp=sharing', 'https://www.tertiarycourses.com.sg/media/courses/brochures/TGS-2025052674-SG.pdf')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'WSQ - Fast-Track to Unreal Game Development for Aspiring Game Developers', 'WSQ - AI Vibe Coding for Game Development')
  WHERE entity_id = @e AND attribute_id = @a_sdesc;
