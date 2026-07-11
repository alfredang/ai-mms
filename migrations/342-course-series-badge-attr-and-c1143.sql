-- Course "series badge" — a short red pill rendered just after the Course Code
-- on the product page (view.phtml, .course-series-badge). Reusable: any course
-- tagged into a marketing series (e.g. "AI Vibe Coding Series") carries the
-- badge by setting this attribute.
--
-- 1) Creates the course_series_badge attribute (global scope, varchar).
-- 2) Assigns it to the "General" group of every product attribute set — without
--    a set assignment the product model does not load the attribute, so
--    view.phtml's getData('course_series_badge') returns null and nothing
--    renders.
-- 3) Tags every non-WSQ (C-prefix) AI Vibe Coding course with the badge.
--
-- Re-runnable: attribute create is guarded; assignment is INSERT IGNORE; the
-- value write is INSERT ... ON DUPLICATE KEY UPDATE. store_id 0 (single SG store).

-- 1) Create the attribute if missing.
SET @existing := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge' LIMIT 1);
INSERT INTO eav_attribute (entity_type_id, attribute_code, backend_type, frontend_input, frontend_label, is_required, is_user_defined, is_unique, note)
SELECT 4, 'course_series_badge', 'varchar', 'text', 'Series Badge', 0, 1, 0,
       'Short red pill shown after the Course Code on the product page (e.g. "AI Vibe Coding Series"). Leave empty for no badge.'
FROM DUAL WHERE @existing IS NULL;
SET @attr_series := IFNULL(@existing, LAST_INSERT_ID());
INSERT IGNORE INTO catalog_eav_attribute (attribute_id, is_global, is_visible, used_in_product_listing) VALUES (@attr_series, 1, 1, 0);

-- 2) Assign to the "General" group of every product attribute set.
INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @attr_series, 60
FROM eav_attribute_group eag
JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
WHERE eag.attribute_group_name = 'General' AND eas.entity_type_id = 4;

-- 3) Tag every non-WSQ (C-prefix) AI Vibe Coding course.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_series, 0, e.entity_id, 'AI Vibe Coding Series'
FROM catalog_product_entity e
WHERE e.sku IN ('C138', 'C349', 'C384', 'C430', 'C576', 'C603', 'C683', 'C818', 'C989', 'C1074', 'C1143', 'C1231', 'C1800')
ON DUPLICATE KEY UPDATE value = VALUES(value);
