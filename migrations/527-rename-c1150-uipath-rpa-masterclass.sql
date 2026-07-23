-- Rename C1150: "RPA with UIPath" -> "UIPath RPA Masterclass"
-- Rebrand only: name, meta_title/description/keyword, image labels + gallery
-- label. The curriculum (topics/description), price and duration are
-- intentionally kept. url_key stays rpa-with-uipath (precedent C1013/C947/C950:
-- keep the slug — no url_path drop / rewrite reindex churn, no 301 needed).
-- Cover NOT re-rendered here (needs the CourseImage pipeline + R2 upload);
-- the existing C1150-*.png cover still carries the old title — regenerate as a
-- follow-up on prod web (batch cover render) if the baked-in title matters.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C1150.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1150');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'UIPath RPA Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'UIPath RPA Masterclass | Tertiary Courses Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master Robotic Process Automation with UiPath in this hands-on masterclass — build automation workflows in UiPath Studio, work with the Orchestrator, and automate repetitive business tasks to boost workplace productivity.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'UIPath RPA Masterclass, UiPath Course, UiPath Training, RPA Course, Robotic Process Automation, UiPath Studio, UiPath Orchestrator, Workflow Automation, Business Automation, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'UIPath RPA Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'UIPath RPA Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'UIPath RPA Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Product-page zoom gallery renders the per-image gallery label, not the EAV labels
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'UIPath RPA Masterclass'
WHERE g.entity_id = @e AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_mk);
