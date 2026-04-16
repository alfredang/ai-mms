-- Populate course_image_url for all products that have a local image path
-- but no external URL set yet. Uses the original production site as the
-- image source so both local dev and live deployments show images.
--
-- Idempotent: ON DUPLICATE KEY UPDATE only overwrites empty values.

SET @img_attr   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'image' AND entity_type_id = 4 LIMIT 1);
SET @url_attr   := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'course_image_url' AND entity_type_id = 4 LIMIT 1);

-- Only run if both attributes exist
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @url_attr, 0, img.entity_id,
       CONCAT('https://www.tertiarycourses.com.sg/media/catalog/product', img.value)
FROM catalog_product_entity_varchar img
WHERE img.attribute_id = @img_attr
  AND img.store_id = 0
  AND img.value IS NOT NULL
  AND img.value != ''
  AND img.value != 'no_selection'
  AND @url_attr IS NOT NULL
  AND img.entity_id NOT IN (
      SELECT entity_id FROM catalog_product_entity_varchar
      WHERE attribute_id = @url_attr AND store_id = 0 AND value IS NOT NULL AND value != ''
  )
ON DUPLICATE KEY UPDATE value = IF(value IS NULL OR value = '',
    CONCAT('https://www.tertiarycourses.com.sg/media/catalog/product', img.value),
    value);
