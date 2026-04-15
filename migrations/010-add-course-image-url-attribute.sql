-- Add course_image_url product attribute
-- Lets admins paste a direct external image URL to use as the course thumbnail
-- (useful when the uploaded media file is missing on disk but a public URL exists).
-- The Learner My Classes view prefers this URL when set, falling back to the
-- normal uploaded image otherwise.

-- Skip if attribute already exists (idempotent)
SET @existing := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url' LIMIT 1);

-- Only insert if missing
INSERT INTO eav_attribute (entity_type_id, attribute_code, backend_type, frontend_input, frontend_label, frontend_class, is_required, is_user_defined, is_unique, note)
SELECT 4, 'course_image_url', 'varchar', 'text', 'Course Image URL', 'validate-url', 0, 1, 0,
       'Paste a direct image URL (https://...) to use as the course thumbnail. Overrides the uploaded image if set.'
FROM DUAL WHERE @existing IS NULL;

SET @aid := IFNULL(@existing, LAST_INSERT_ID());

-- catalog_eav_attribute settings (idempotent INSERT IGNORE)
INSERT IGNORE INTO catalog_eav_attribute (attribute_id, is_global, is_visible, used_in_product_listing)
VALUES (@aid, 1, 1, 1);

-- Add to all product attribute sets in the General group (idempotent — UNIQUE constraint on the join cols)
INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @aid, 50
FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eag.attribute_set_id = eas.attribute_set_id
WHERE eag.attribute_group_name = 'General' AND eas.entity_type_id = 4;
