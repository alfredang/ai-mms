-- Fix a typo in the C1143 course title: "React AI Vibe Coding for React
-- Development" -> "AI Vibe Coding for React Development" (drop the stray
-- leading "React"). Corrects the name, the overview mention, SEO meta_title,
-- the branded cover (rendered from the name) and the url_key. Topics, price,
-- duration, badge and funding are unchanged.
--
-- The url_key correction lands BEFORE the post-deploy catalog_url reindex, so
-- the old slug (react-essential-training) 301s DIRECTLY to
-- ai-vibe-coding-for-react-development with no intermediate hop. Market-neutral,
-- applies to SG/MY/GH. Store scope 0. Idempotent. No content line ends in ';'.

SET @entity_id := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1143');

SET @attr_name             := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @attr_short_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @attr_meta_title        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @attr_course_image_url  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @attr_url_key           := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

-- name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_name, 0, @entity_id, 'AI Vibe Coding for React Development')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_title, 0, @entity_id, 'AI Vibe Coding for React Development | Tertiary Courses Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- url_key
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_url_key, 0, @entity_id, 'ai-vibe-coding-for-react-development')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- course_image_url (cover regenerated with the corrected name)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_course_image_url, 0, @entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1143-20260711-091516.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- overview: drop the stray leading "React " in the first sentence
UPDATE catalog_product_entity_text
SET value = REPLACE(value, 'with React AI Vibe Coding for React Development.', 'with AI Vibe Coding for React Development.')
WHERE entity_id = @entity_id AND attribute_id = @attr_short_description AND store_id = 0;
