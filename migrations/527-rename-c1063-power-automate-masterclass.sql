-- Rename C1063: "Microsoft Power Automate Training" -> "Power Automate Masterclass"
-- Rebrand only: name, overview intro, meta, image labels. The curriculum
-- (description), price ($350) and duration are intentionally kept.
-- url_key stays microsoft-power-automate-essential-training (precedent
-- C1013/C947/C950: keep the slug — no url_path drop / rewrite reindex churn,
-- no 301 needed).
-- C1063 carries no funding-badge tags and its overview has no Funding block,
-- so nothing funding-related to touch (matches C1013).
-- Cover: re-render from the new title via the admin cover dialog and upload to
-- R2, then update course_image_url (left untouched here — see note below).
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C1063.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1063');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Power Automate Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Dive into the world of automation with our hands-on Power Automate Masterclass. This masterclass is designed to equip professionals with the skills to streamline business processes and enhance productivity. Discover how to create, manage, and deploy automated workflows, integrating with various Microsoft applications and services. Our expert-led training provides hands-on experience, ensuring you can apply these powerful tools effectively in real-world scenarios.</p>
<p>Whether you''re looking to optimize data management, improve team collaboration, or automate repetitive tasks, this masterclass offers the knowledge and practical skills needed. You will learn to navigate the Power Automate interface with ease, design efficient workflows, and troubleshoot common issues. By the end of this masterclass, you''ll have mastered the art of using Power Automate to transform business operations, making you an invaluable asset in today''s fast-paced, technology-driven workplace.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Power Automate Masterclass | Tertiary Courses Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master workflow automation in this hands-on Power Automate Masterclass — build, manage, and deploy automated workflows across Microsoft apps to boost business efficiency and process management.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Power Automate Masterclass, Power Automate Course, Power Automate Training, Workflow Automation, Business Process Automation, Microsoft Power Platform, Automated Workflows, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Power Automate Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Power Automate Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Power Automate Masterclass' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Clear per-store overrides so partner store scopes can't shadow store 0.
DELETE v FROM catalog_product_entity_varchar v
WHERE v.entity_id = @e AND v.store_id <> 0
  AND v.attribute_id IN (@a_name, @a_mt, @a_md, @a_il, @a_sil, @a_til);
DELETE v FROM catalog_product_entity_text v
WHERE v.entity_id = @e AND v.store_id <> 0
  AND v.attribute_id IN (@a_short, @a_mk);
