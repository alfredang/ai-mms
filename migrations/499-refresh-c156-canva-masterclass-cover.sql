-- Refresh the course cover for C156 (Canva Design Masterclass). Its
-- course_image_url still pointed at the 2026-05-23 cover rendered with the OLD
-- "Visual Magic with Canva" title. New cover rendered 2026-07-17 with the
-- current name (image labels already aligned by migration 498).
-- Guarded with @e IS NOT NULL so it is a no-op on sites without the SKU.
-- Store scope 0 (per-store cover overrides cleared). Idempotent.

SET @a_ciu := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C156');
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C156-20260717-162524.png' FROM DUAL WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_varchar
WHERE @e IS NOT NULL AND entity_id=@e AND store_id<>0 AND attribute_id=@a_ciu;
