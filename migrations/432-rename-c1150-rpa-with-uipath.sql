-- Rename course C1150 from "UIPath RPA Essential Training: Unleash Your
-- Workplace Productivity" to "RPA with UIPath". Name + meta_title only; topics,
-- price, url_key unchanged. Store scope 0. Idempotent. No content line ends in a
-- semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1150');
SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_mt   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'RPA with UIPath') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'RPA with UIPath') ON DUPLICATE KEY UPDATE value = VALUES(value);
