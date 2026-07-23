-- Rename C348 "ITIL 4 Foundation Training (Voucher Included)"
--                -> "ITIL 4 Foundation Training"
--
-- Title-only rename: name + image labels + new branded cover. The url_key
-- (itil-4-foundation-it-service-management-exam-prep) never contained
-- "voucher", so the slug is untouched and no 301 is needed. Meta title/
-- description don't mention the voucher either — left as-is.
--
-- New cover rendered from the new title (no funding badges on C348) and
-- uploaded to R2: course-covers/C348-20260721-070825.png (verified 200,
-- 111603 bytes). Old cover: course-covers/C348-20260717-162840.png.
--
-- Clears per-store overrides so partner store scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C348.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C348');

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_il   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_ciu  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'ITIL 4 Foundation Training' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'ITIL 4 Foundation Training' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'ITIL 4 Foundation Training' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'ITIL 4 Foundation Training' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C348-20260721-070825.png'
FROM DUAL WHERE @e IS NOT NULL AND @a_ciu IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear per-store overrides so partner store scopes can't shadow store 0.
DELETE v FROM catalog_product_entity_varchar v
WHERE v.entity_id = @e AND v.store_id <> 0
  AND v.attribute_id IN (@a_name, @a_il, @a_sil, @a_til, @a_ciu);
