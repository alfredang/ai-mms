-- Rename C879: "AI Vibe Coding for Quick iOS Mobile Apps Deployment"
--            -> "AI Vibe Coding for iOS Mobile Apps Development"
-- url_key is already ai-vibe-coding-for-ios-mobile-apps-development (unchanged).
-- Idempotent; scoped to SKU C879 (SG non-WSQ) only.

SET @eid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C879');
SET @attr_name       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @attr_meta_title := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @attr_short_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @attr_cover      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

UPDATE catalog_product_entity_varchar
SET value = 'AI Vibe Coding for iOS Mobile Apps Development'
WHERE entity_id = @eid AND attribute_id IN (@attr_name, @attr_meta_title);

UPDATE catalog_product_entity_text
SET value = REPLACE(value, 'AI Vibe Coding for Quick iOS Mobile Apps Deployment', 'AI Vibe Coding for iOS Mobile Apps Development')
WHERE entity_id = @eid AND attribute_id = @attr_short_desc;

UPDATE catalog_product_entity_varchar
SET value = 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C879-20260717-180749.png'
WHERE entity_id = @eid AND attribute_id = @attr_cover;
