-- "Most Popular" course flag — a yes/no product attribute (course_popular). When set, the storefront
-- shows a three-flame "Most Popular" ribbon on the course cover (product page + category listing cards)
-- and a matching pill next to the Course Code (view.phtml / list.phtml, MMD_CourseImage::isPopularCourse).
--
-- 1) Creates course_popular (global int, boolean) on every site — schema only, no content.
-- 2) Assigns it to the "General" group of every product attribute set.
-- 3) SG only (store guard): flags the three most popular WSQ courses (user, 2026-10-25):
--      TGS-2025052468  WSQ - Agentic AI Applications with Claude Code
--      TGS-2023035977  WSQ - Agentic AI Automation with n8n
--      TGS-2024043855  WSQ - Creating Engaging Videos with Generative AI (GenAI)
--
-- Idempotent.

SET @existing := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_popular' LIMIT 1);
INSERT INTO eav_attribute (entity_type_id, attribute_code, backend_type, frontend_input, frontend_label, source_model, is_required, is_user_defined, is_unique, default_value, note)
SELECT 4, 'course_popular', 'int', 'boolean', 'Most Popular Course', 'eav/entity_attribute_source_boolean', 0, 1, 0, '0',
       'Shows the three-flame "Most Popular" ribbon on the course cover and next to the Course Code.'
  FROM DUAL WHERE @existing IS NULL;
SET @attr_popular := IFNULL(@existing, LAST_INSERT_ID());
INSERT IGNORE INTO catalog_eav_attribute (attribute_id, is_global, is_visible, used_in_product_listing) VALUES (@attr_popular, 1, 1, 0);

INSERT IGNORE INTO eav_entity_attribute (entity_type_id, attribute_set_id, attribute_group_id, attribute_id, sort_order)
SELECT 4, eag.attribute_set_id, eag.attribute_group_id, @attr_popular, 61
  FROM eav_attribute_group eag
  JOIN eav_attribute_set eas ON eas.attribute_set_id = eag.attribute_set_id
 WHERE eag.attribute_group_name = 'General' AND eas.entity_type_id = 4;

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @attr_popular, 0, e.entity_id, 1
  FROM catalog_product_entity e
 WHERE @sg = 1 AND TRIM(e.sku) IN ('TGS-2025052468', 'TGS-2023035977', 'TGS-2024043855')
ON DUPLICATE KEY UPDATE value = VALUES(value);
