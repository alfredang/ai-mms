-- 1210: Convert C811 "PL-7001 Create and manage canvas apps with Power Apps"
-- into "Job Assessment and Redesign for AI Adoption", and move it from the
-- Microsoft Copilot Series to the AI Applications Series + its AI for HR
-- subcategory.
--
-- The SKU stays C811 (as requested). New name, new url_key with a 301 from
-- the old one, freshly rendered branded cover on R2, new meta.
--
-- It also leaves the Power Platform / Power Apps / Microsoft Copilot software
-- trees, which no longer describe the course:
--   137 Microsoft Copilot, 218 Power Platform, 233 Power Apps,
--   11 Microsoft, 53 Software Training
-- and the Microsoft Copilot Series (357). It keeps All Courses (3) and
-- Infocomm Technology (55), and gains AI Courses (252).
--
-- Placed at the head of the AI for HR subcategory's non-WSQ block and in the
-- AI Applications Series parent listing's HR position — both in the 101+
-- band, after every WSQ/CASL/IBF course. Both categories carry a curated
-- non-WSQ order so these positions survive the nightly sweep.
--
-- SG-guarded; C-prefix SKU and these url_keys are SG-only (partner no-op).
-- Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_pname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_purlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_pmetat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_pmetad  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_pcimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @e811 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C811' LIMIT 1);

SET @apps := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1);
SET @hr := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-hr-courses' LIMIT 1);
SET @copilot := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'microsoft-copilot-series' LIMIT 1);
SET @aicourses := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-courses' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Rename + re-slug + re-cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e811, 'Job Assessment and Redesign for AI Adoption'
FROM dual WHERE @e811 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e811 AND attribute_id = @a_pname AND store_id <> 0
  AND @e811 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e811, 'job-assessment-and-redesign-for-ai-adoption'
FROM dual WHERE @e811 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e811 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e811 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e811, 'Job Assessment and Redesign for AI Adoption | Tertiary Courses Singapore'
FROM dual WHERE @e811 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e811, 'Assess and redesign jobs for AI adoption - task analysis, role redesign, reskilling pathways and workforce transition planning.'
FROM dual WHERE @e811 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e811, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C811-20260830-060727.png'
FROM dual WHERE @e811 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) 301 the old URL, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'pl-7001-create-and-manage-canvas-apps-with-power-apps.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c811-301', 'pl-7001-create-and-manage-canvas-apps-with-power-apps.html',
       'job-assessment-and-redesign-for-ai-adoption.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e811) AND store_id = 1
  AND request_path <> 'job-assessment-and-redesign-for-ai-adoption.html'
  AND @e811 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e811), 'job-assessment-and-redesign-for-ai-adoption.html',
       CONCAT('catalog/product/view/id/', @e811), 1, @e811
FROM dual WHERE @e811 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 3) Leave the Microsoft Copilot Series and the Power Platform trees.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e811
  AND cp.category_id IN (@copilot, 137, 218, 233, 11, 53)
  AND @e811 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e811
  AND i.category_id IN (@copilot, 137, 218, 233, 11, 53)
  AND @e811 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 4) Join AI Courses, the AI Applications Series and the AI for HR subcategory.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT c.id, @e811, 101
FROM (SELECT @aicourses AS id UNION ALL SELECT @apps UNION ALL SELECT @hr) c
WHERE c.id IS NOT NULL AND @e811 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT c.id, p.entity_id, 101, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN (SELECT @aicourses AS id UNION ALL SELECT @apps UNION ALL SELECT @hr) c ON c.id IS NOT NULL
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'C811' AND @is_sg > 0
GROUP BY c.id, p.entity_id, s.store_id;

-- ---------------------------------------------------------------------------
-- 5) Order: head of the AI for HR non-WSQ block, and the HR slot on the
--    AI Applications Series parent (after the Robotics group, before ML).
-- ---------------------------------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku WHEN 'C811' THEN 101 WHEN 'C820' THEN 102 END
WHERE cp.category_id = @hr AND p.sku IN ('C811', 'C820');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku WHEN 'C811' THEN 101 WHEN 'C820' THEN 102 END
WHERE i.category_id = @hr AND p.sku IN ('C811', 'C820');

-- Parent listing: C811 and C820 (the HR pair) sit after Robotics (C852, 119)
-- and before the Machine Learning group, which shifts down by two.
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C811'  THEN 120
  WHEN 'C820'  THEN 121
  WHEN 'C430'  THEN 122
  WHEN 'C592'  THEN 123
  WHEN 'C188'  THEN 124
  WHEN 'C539'  THEN 125
  WHEN 'C1071' THEN 126
  WHEN 'C926'  THEN 127
  WHEN 'C1759' THEN 128
  WHEN 'C19'   THEN 129
  WHEN 'C1330' THEN 130
  WHEN 'C279'  THEN 131
  WHEN 'C476'  THEN 132
  WHEN 'C1750' THEN 133
END
WHERE cp.category_id = @apps
  AND p.sku IN ('C811','C820','C430','C592','C188','C539','C1071','C926','C1759','C19','C1330','C279','C476','C1750');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C811'  THEN 120
  WHEN 'C820'  THEN 121
  WHEN 'C430'  THEN 122
  WHEN 'C592'  THEN 123
  WHEN 'C188'  THEN 124
  WHEN 'C539'  THEN 125
  WHEN 'C1071' THEN 126
  WHEN 'C926'  THEN 127
  WHEN 'C1759' THEN 128
  WHEN 'C19'   THEN 129
  WHEN 'C1330' THEN 130
  WHEN 'C279'  THEN 131
  WHEN 'C476'  THEN 132
  WHEN 'C1750' THEN 133
END
WHERE i.category_id = @apps
  AND p.sku IN ('C811','C820','C430','C592','C188','C539','C1071','C926','C1759','C19','C1330','C279','C476','C1750');
