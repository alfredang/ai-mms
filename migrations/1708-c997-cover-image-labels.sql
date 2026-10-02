-- C997 Business Transformation with AI Agents: the cover image alt/title (image_label, small_image_label,
-- thumbnail_label + gallery labels) still named the recycled entity's retired course "Google Cloud Certified
-- Professional Machine Learning Engineer Training". Point them at the course title (the cover PNG itself is
-- already correct). Follow-up to 1707.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C997' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);
SET @title := 'Business Transformation with AI Agents';

UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @title
 WHERE @ok AND g.entity_id = @pid;
