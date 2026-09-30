-- C28 AI Agent Security: clear two leftovers from the product entity's previous life
-- (AI Vibe Coding for PHP and MySQL).
--
-- 1. Job Roles (`whoshouldattend`, store 0) still listed PHP / MariaDB audiences —
--    copied from the WSQ twin TGS-2025060473, same syllabus.
-- 2. Cover alt/title text (image_label, small_image_label, thumbnail_label) still read
--    "AI Vibe Coding for PHP and MySQL" — set to the course name. The cover PNG itself
--    already shows "AI Agent Security".
--
-- Joined on the SG-only TGS- twin, so partner sites no-op. Idempotent.

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C28'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'whoshouldattend' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025060473'
  JOIN catalog_product_entity_text pt ON pt.entity_id = p.entity_id AND pt.attribute_id = t.attribute_id AND pt.store_id = 0
   SET t.value = pt.value
 WHERE t.store_id = 0
   AND LENGTH(pt.value) = CHAR_LENGTH(pt.value);

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C28'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
                      AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2025060473'
   SET v.value = 'AI Agent Security'
 WHERE v.value LIKE '%PHP%';
