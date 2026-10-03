-- C1415: "DP-900 Azure Data Fundamentals Training" -> "DP-900 Azure Data Fundamentals Exam Prep", the
-- 2-day non-WSQ twin of TGS-2023036641 (WSQ - Microsoft Azure Data Fundamentals (DP-900)).
--
-- 1. name, cover alt labels, meta title/description (the old description promised WSQ funding).
--    url_key is already dp-900-azure-data-fundamentals-exam-prep -> no slug change, no 301s.
-- 2. About + topics copied from the WSQ parent (opener names the new title).
-- 3. Funding block -> the parent's bare URL (it pointed at a 301 alias).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): cover re-render (title is baked into the PNG), schedule
-- template -> B01, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1415' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023036641' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'DP-900 Azure Data Fundamentals Exam Prep';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ------------------------------------------------------------- name -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @new_title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'DP-900 Azure Data Fundamentals Exam Prep in Singapore: prepare for the Microsoft DP-900 exam with core data concepts, relational and non-relational data on Azure, and analytics workloads.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'DP-900 Azure Data Fundamentals Exam Prep, DP-900, Azure Data Fundamentals, Microsoft Azure, Relational Data, Non-Relational Data, Azure Analytics, Microsoft Certification, Tertiary Courses'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc) AND store_id <> 0;

-- ---------------------------------------------- About + topics (parent) ----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid,
       REPLACE(value, 'with our Microsoft Azure Data Fundamentals course.', 'with our DP-900 Azure Data Fundamentals Exam Prep course.')
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_short AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, value
  FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @src AND attribute_id = @a_desc AND store_id = 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-microsoft-azure-data-fundamentals-dp-900.html" title="WSQ - Microsoft Azure Data Fundamentals (DP-900)">WSQ - Microsoft Azure Data Fundamentals (DP-900)</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C1415_funding_and_grant';
