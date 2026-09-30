-- C140 Blender Masterclass = non-WSQ twin of TGS-2026065705
-- (WSQ - 3D Modelling with Blender for Beginners), converted to a 2-day course.
--
-- 1. Fee $350 -> $700 (2 days at the standard $350/day), every scope row.
-- 2. Duration tile 7.5 -> 15 hrs; Sessions tile 1 -> 2.
-- 3. Course topics (`description`, store 0) and "What's This Course About"
--    (`short_description`, store 0) copied verbatim from the WSQ parent — the parent's
--    About carries no WSQ wording and no day count.
-- 4. meta_description drops the "1-day" day count.
-- 5. Funding block links to the WSQ twin (it had no redirect at all).
--
-- The schedule template (B17) is switched through the code path, not SQL.
-- Every statement joins on the TGS- parent, so partner sites (no parent) are no-ops.
-- Idempotent: re-running writes the same values.

UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity c ON c.entity_id = d.entity_id AND TRIM(c.sku) = 'C140'
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.attribute_code = 'price' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026065705'
   SET d.value = 700;

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C140'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'duration' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026065705'
   SET v.value = '15';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C140'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'sessions' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026065705'
   SET v.value = '2';

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C140'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026065705'
  JOIN catalog_product_entity_text pt ON pt.entity_id = p.entity_id AND pt.attribute_id = t.attribute_id AND pt.store_id = 0
   SET t.value = pt.value
 WHERE t.store_id = 0
   AND LENGTH(pt.value) = CHAR_LENGTH(pt.value);

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C140'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'short_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026065705'
  JOIN catalog_product_entity_text pt ON pt.entity_id = p.entity_id AND pt.attribute_id = t.attribute_id AND pt.store_id = 0
   SET t.value = pt.value
 WHERE t.store_id = 0
   AND LENGTH(pt.value) = CHAR_LENGTH(pt.value)
   AND pt.value NOT LIKE '%WSQ%'
   AND pt.value NOT LIKE '%day%';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C140'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'meta_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026065705'
   SET v.value = 'Learn 3D modelling in this hands-on Blender Masterclass. Model, sculpt, animate, light and render 3D prototypes in Blender at Tertiary Courses Singapore.';

UPDATE cms_block b
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026065705'
   SET b.content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-3d-modelling-with-blender-for-beginners.html" title="WSQ - 3D Modelling with Blender for Beginners">WSQ - 3D Modelling with Blender for Beginners</a></span></p>'
 WHERE b.identifier = 'course_C140_funding_and_grant';
