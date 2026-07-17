-- Rename C1074: "AI Vibe Coding for Mobile Apps Development"
--             -> "AI Vibe Coding for Mobile Apps"
-- url_key stays ai-vibe-coding-for-mobile-apps-development (series rule: never change slugs).
-- Idempotent; scoped to SKU C1074 (SG non-WSQ) only.

SET @eid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1074');
SET @attr_name       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @attr_meta_title := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @attr_cover      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding for Mobile Apps'
WHERE entity_id = @eid AND attribute_id IN (@attr_name, @attr_meta_title);

UPDATE catalog_product_entity_varchar
SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1074-20260717-180826.png'
WHERE entity_id = @eid AND attribute_id = @attr_cover;
