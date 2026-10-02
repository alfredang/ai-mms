-- C922: the cover image alt/title (image_label, small_image_label, thumbnail_label) still read the recycled
-- entity's old name "AI Devops with Jenkins" after the 1230 rename to "Fine Tuning Open Source LLM".
-- Set all three to the current name at store 0 and drop store-scope overrides. SG-guarded, idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C922' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, @pid, 'Fine Tuning Open Source LLM'
  FROM eav_attribute a
 WHERE @ok AND a.entity_type_id = 4 AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE v FROM catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
 WHERE @ok AND v.entity_id = @pid AND v.store_id <> 0;
