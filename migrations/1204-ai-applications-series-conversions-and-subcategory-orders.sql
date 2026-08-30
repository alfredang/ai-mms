-- 1204: AI Applications Series — convert 3 exam-prep courses into business
-- courses, rename the General subcategory, add an AI for Robotics
-- subcategory, and pin the curated non-WSQ order in each subcategory.
--
-- A) Course conversions (SG non-WSQ, C-prefix). Each gets a new name, new
--    url_key (301 from the old one), a freshly rendered branded cover on R2,
--    new meta, and is moved out of its exam-prep category trees:
--      C798 Pearson Vue Certified IT Specialist AI Training
--             -> Business Innovation with AI          (syllabus from CASL - Business Innovation with Artificial Intelligence)
--      C997 Google Cloud Certified Professional ML Engineer Training
--             -> Business Transformation with AI Agents (syllabus from WSQ - AI Agents for Business)
--      C840 DP-100 Azure Data Scientist Associate Training
--             -> AI for Product Development
--    Syllabus is copied from the donor course at store 0 where one is named.
--
-- B) 'AI for General Applications' -> 'AI for Business' (new url_key + 301).
--
-- C) Repurpose the deactivated empty 'eLearning Content Creation' category as
--    'AI for Robotics', under the AI Applications Series.
--
-- D) Curated non-WSQ order in each subcategory, after the WSQ/CASL/IBF block.
--    Every touched subcategory url_key is added to
--    mmd/category_ordering/curated_url_keys so the nightly sweep preserves it.
--
-- SG-guarded; C-prefix SKUs and these url_keys are SG-only (partner no-op).
-- Positive positions only (see 1195). Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_pname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_purlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_pmetat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_pmetad  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_pdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_psdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_pcimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_curlpath:= (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_path');
SET @a_cname   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_cactive := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_active');
SET @a_cmenu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'include_in_menu');
SET @a_canchor := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'is_anchor');
SET @a_clayout := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'page_layout');

SET @apps := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1);
SET @appspath := (SELECT path FROM catalog_category_entity WHERE entity_id = @apps);

-- ===== A: C798 -> Business Innovation with AI =====

SET @e_C798 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C798' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e_C798, 'Business Innovation with AI' FROM dual WHERE @e_C798 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C798 AND attribute_id = @a_pname AND store_id <> 0 AND @e_C798 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e_C798, 'business-innovation-with-ai' FROM dual WHERE @e_C798 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C798 AND attribute_id = @a_purlkey AND store_id <> 0 AND @e_C798 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e_C798, 'Business Innovation with AI | Tertiary Courses Singapore' FROM dual WHERE @e_C798 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e_C798, 'Discover how AI creates new business value - use cases, opportunities and an adoption roadmap for innovating with artificial intelligence.' FROM dual WHERE @e_C798 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e_C798, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C798-20260830-053751.png' FROM dual WHERE @e_C798 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- syllabus + overview copied from the donor course (store 0)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e_C798, d.value
FROM (SELECT value FROM catalog_product_entity_text
      WHERE entity_id = 1106 AND store_id = 0 AND attribute_id = @a_pdesc LIMIT 1) d
WHERE @e_C798 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e_C798, d.value
FROM (SELECT value FROM catalog_product_entity_text
      WHERE entity_id = 1106 AND store_id = 0 AND attribute_id = @a_psdesc LIMIT 1) d
WHERE @e_C798 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM core_url_rewrite
WHERE request_path = 'pearson-vue-certified-it-specialist-artificial-intelligence-training.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c798-301', 'pearson-vue-certified-it-specialist-artificial-intelligence-training.html', 'business-innovation-with-ai.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e_C798) AND store_id = 1
  AND request_path <> 'business-innovation-with-ai.html' AND @e_C798 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e_C798), 'business-innovation-with-ai.html', CONCAT('catalog/product/view/id/', @e_C798), 1, @e_C798
FROM dual WHERE @e_C798 IS NOT NULL AND @is_sg > 0;

-- leave the exam-prep category trees
DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e_C798 AND cp.category_id IN (182,402,435) AND @e_C798 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e_C798 AND i.category_id IN (182,402,435) AND @e_C798 IS NOT NULL AND @is_sg > 0;

-- ===== A: C997 -> Business Transformation with AI Agents =====

SET @e_C997 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C997' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e_C997, 'Business Transformation with AI Agents' FROM dual WHERE @e_C997 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C997 AND attribute_id = @a_pname AND store_id <> 0 AND @e_C997 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e_C997, 'business-transformation-with-ai-agents' FROM dual WHERE @e_C997 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C997 AND attribute_id = @a_purlkey AND store_id <> 0 AND @e_C997 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e_C997, 'Business Transformation with AI Agents | Tertiary Courses Singapore' FROM dual WHERE @e_C997 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e_C997, 'Transform business operations with AI agents - agent capabilities, workflow design and practical deployment for enterprise use cases.' FROM dual WHERE @e_C997 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e_C997, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C997-20260830-053751.png' FROM dual WHERE @e_C997 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- syllabus + overview copied from the donor course (store 0)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e_C997, d.value
FROM (SELECT value FROM catalog_product_entity_text
      WHERE entity_id = 1347 AND store_id = 0 AND attribute_id = @a_pdesc LIMIT 1) d
WHERE @e_C997 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e_C997, d.value
FROM (SELECT value FROM catalog_product_entity_text
      WHERE entity_id = 1347 AND store_id = 0 AND attribute_id = @a_psdesc LIMIT 1) d
WHERE @e_C997 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM core_url_rewrite
WHERE request_path = 'google-professional-machine-learning-engineer-exam-prep.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c997-301', 'google-professional-machine-learning-engineer-exam-prep.html', 'business-transformation-with-ai-agents.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e_C997) AND store_id = 1
  AND request_path <> 'business-transformation-with-ai-agents.html' AND @e_C997 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e_C997), 'business-transformation-with-ai-agents.html', CONCAT('catalog/product/view/id/', @e_C997), 1, @e_C997
FROM dual WHERE @e_C997 IS NOT NULL AND @is_sg > 0;

-- leave the exam-prep category trees
DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e_C997 AND cp.category_id IN (182,419,420,184,87) AND @e_C997 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e_C997 AND i.category_id IN (182,419,420,184,87) AND @e_C997 IS NOT NULL AND @is_sg > 0;

-- ===== A: C840 -> AI for Product Development =====

SET @e_C840 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C840' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e_C840, 'AI for Product Development' FROM dual WHERE @e_C840 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C840 AND attribute_id = @a_pname AND store_id <> 0 AND @e_C840 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e_C840, 'ai-for-product-development' FROM dual WHERE @e_C840 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e_C840 AND attribute_id = @a_purlkey AND store_id <> 0 AND @e_C840 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e_C840, 'AI for Product Development | Tertiary Courses Singapore' FROM dual WHERE @e_C840 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e_C840, 'Apply AI across the product development lifecycle - ideation, prototyping, user research and data-driven product decisions.' FROM dual WHERE @e_C840 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e_C840, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C840-20260830-053751.png' FROM dual WHERE @e_C840 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM core_url_rewrite
WHERE request_path = 'dp-100-azure-data-scientist-associate-exam-prep.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c840-301', 'dp-100-azure-data-scientist-associate-exam-prep.html', 'ai-for-product-development.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e_C840) AND store_id = 1
  AND request_path <> 'ai-for-product-development.html' AND @e_C840 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e_C840), 'ai-for-product-development.html', CONCAT('catalog/product/view/id/', @e_C840), 1, @e_C840
FROM dual WHERE @e_C840 IS NOT NULL AND @is_sg > 0;

-- leave the exam-prep category trees
DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e_C840 AND cp.category_id IN (182,135,358,411,413,185,87,11) AND @e_C840 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e_C840 AND i.category_id IN (182,135,358,411,413,185,87,11) AND @e_C840 IS NOT NULL AND @is_sg > 0;


-- ===== B: rename 'AI for General Applications' -> 'AI for Business' =====

SET @business := COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-business' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-general-applications' LIMIT 1)
);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cname, 0, @business, 'AI for Business'
FROM dual WHERE @business IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_curlkey, 0, @business, 'ai-for-business'
FROM dual WHERE @business IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-business.html'
WHERE entity_id = @business AND attribute_id = @a_curlpath AND @business IS NOT NULL AND @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-for-general-applications.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/ai-for-general-applications-301', 'ai-for-general-applications.html', 'ai-for-business.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('category/', @business) AND store_id = 1
  AND request_path <> 'ai-for-business.html' AND @business IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, category_id)
SELECT 1, CONCAT('category/', @business), 'ai-for-business.html',
       CONCAT('catalog/category/view/id/', @business), 1, @business
FROM dual WHERE @business IS NOT NULL AND @is_sg > 0;

-- ===== C: repurpose an empty deactivated category as 'AI for Robotics' =====

SET @robotics := IF(@is_sg > 0, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-robotics' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'elearning-content-creation-courses' LIMIT 1)
), NULL);

SET @rob_oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @robotics);
SET @rob_move := IF(@robotics IS NOT NULL AND @apps IS NOT NULL
  AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @robotics) <> @apps, 1, 0);
SET @rob_pos := (SELECT COALESCE(MAX(position), 0) + 1 FROM (SELECT * FROM catalog_category_entity) x WHERE x.parent_id = @apps);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @rob_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@rob_oldpath, '/', ','))
  AND entity_id <> @robotics AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @rob_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@rob_oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1,
    position = @rob_pos
WHERE @rob_move = 1 AND entity_id = @robotics;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cname, 0, @robotics, 'AI for Robotics'
FROM dual WHERE @robotics IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_curlkey, 0, @robotics, 'ai-for-robotics'
FROM dual WHERE @robotics IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-robotics.html'
WHERE entity_id = @robotics AND attribute_id = @a_curlpath AND @robotics IS NOT NULL;

DELETE FROM catalog_category_entity_int
WHERE entity_id = @robotics AND attribute_id IN (@a_cactive, @a_cmenu) AND store_id <> 0 AND @robotics IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cactive, 0, @robotics, 1 FROM dual WHERE @robotics IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, @robotics, 0 FROM dual WHERE @robotics IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_canchor, 0, @robotics, 1 FROM dual WHERE @robotics IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @robotics AND attribute_id = @a_clayout AND @robotics IS NOT NULL;

-- ===== C2: repurpose another empty deactivated category as 'AI for HR' =====
-- Slug is 'ai-for-hr-courses' (matching the finance/healthcare siblings)
-- because 'ai-for-hr.html' is the PRODUCT url of C820 AI for HR, which keeps
-- its own URL. See feedback_flat_url_collision_suffix_explosion.

SET @hr := IF(@is_sg > 0, COALESCE(
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-hr-courses' LIMIT 1),
  (SELECT v.entity_id FROM catalog_category_entity_varchar v
   WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'learning-management-system-lms-courses' LIMIT 1)
), NULL);

SET @hr_oldpath := (SELECT path FROM catalog_category_entity WHERE entity_id = @hr);
SET @hr_move := IF(@hr IS NOT NULL AND @apps IS NOT NULL
  AND (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @hr) <> @apps, 1, 0);
SET @hr_pos := (SELECT COALESCE(MAX(position), 0) + 1 FROM (SELECT * FROM catalog_category_entity) x WHERE x.parent_id = @apps);

UPDATE catalog_category_entity
SET children_count = children_count - 1
WHERE @hr_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@hr_oldpath, '/', ','))
  AND entity_id <> @hr AND NOT FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','));

UPDATE catalog_category_entity
SET children_count = children_count + 1
WHERE @hr_move = 1 AND FIND_IN_SET(entity_id, REPLACE(@appspath, '/', ','))
  AND NOT FIND_IN_SET(entity_id, REPLACE(@hr_oldpath, '/', ','));

UPDATE catalog_category_entity
SET parent_id = @apps,
    path = CONCAT(@appspath, '/', entity_id),
    level = (LENGTH(@appspath) - LENGTH(REPLACE(@appspath, '/', ''))) + 1,
    position = @hr_pos
WHERE @hr_move = 1 AND entity_id = @hr;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cname, 0, @hr, 'AI for HR' FROM dual WHERE @hr IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_curlkey, 0, @hr, 'ai-for-hr-courses' FROM dual WHERE @hr IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity_varchar
SET value = 'ai-for-hr-courses.html'
WHERE entity_id = @hr AND attribute_id = @a_curlpath AND @hr IS NOT NULL;

DELETE FROM catalog_category_entity_int
WHERE entity_id = @hr AND attribute_id IN (@a_cactive, @a_cmenu) AND store_id <> 0 AND @hr IS NOT NULL;

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cactive, 0, @hr, 1 FROM dual WHERE @hr IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmenu, 0, @hr, 0 FROM dual WHERE @hr IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_canchor, 0, @hr, 1 FROM dual WHERE @hr IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @hr AND attribute_id = @a_clayout AND @hr IS NOT NULL;

-- ===== D: ai-for-business =====

SET @sc_ai_for_business := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-business' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @sc_ai_for_business, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @sc_ai_for_business IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C798',
    'C997',
    'C840',
    'C831',
    'C165',
    'C398',
    'C155',
    'C817',
    'C864',
    'C711',
    'C1756'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @sc_ai_for_business, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @sc_ai_for_business IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C798',
    'C997',
    'C840',
    'C831',
    'C165',
    'C398',
    'C155',
    'C817',
    'C864',
    'C711',
    'C1756'
  )
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C798' THEN 101
  WHEN 'C997' THEN 102
  WHEN 'C840' THEN 103
  WHEN 'C831' THEN 104
  WHEN 'C165' THEN 105
  WHEN 'C398' THEN 106
  WHEN 'C155' THEN 107
  WHEN 'C817' THEN 108
  WHEN 'C864' THEN 109
  WHEN 'C711' THEN 110
  WHEN 'C1756' THEN 111
END
WHERE cp.category_id = @sc_ai_for_business
  AND p.sku IN (
    'C798',
    'C997',
    'C840',
    'C831',
    'C165',
    'C398',
    'C155',
    'C817',
    'C864',
    'C711',
    'C1756'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C798' THEN 101
  WHEN 'C997' THEN 102
  WHEN 'C840' THEN 103
  WHEN 'C831' THEN 104
  WHEN 'C165' THEN 105
  WHEN 'C398' THEN 106
  WHEN 'C155' THEN 107
  WHEN 'C817' THEN 108
  WHEN 'C864' THEN 109
  WHEN 'C711' THEN 110
  WHEN 'C1756' THEN 111
END
WHERE i.category_id = @sc_ai_for_business
  AND p.sku IN (
    'C798',
    'C997',
    'C840',
    'C831',
    'C165',
    'C398',
    'C155',
    'C817',
    'C864',
    'C711',
    'C1756'
  );

-- ===== D: ai-for-finance-courses =====

SET @sc_ai_for_finance_courses := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-finance-courses' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @sc_ai_for_finance_courses, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @sc_ai_for_finance_courses IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C104',
    'C207',
    'C057',
    'C177',
    'C1164'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @sc_ai_for_finance_courses, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @sc_ai_for_finance_courses IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C104',
    'C207',
    'C057',
    'C177',
    'C1164'
  )
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C104' THEN 101
  WHEN 'C207' THEN 102
  WHEN 'C057' THEN 103
  WHEN 'C177' THEN 104
  WHEN 'C1164' THEN 105
END
WHERE cp.category_id = @sc_ai_for_finance_courses
  AND p.sku IN (
    'C104',
    'C207',
    'C057',
    'C177',
    'C1164'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C104' THEN 101
  WHEN 'C207' THEN 102
  WHEN 'C057' THEN 103
  WHEN 'C177' THEN 104
  WHEN 'C1164' THEN 105
END
WHERE i.category_id = @sc_ai_for_finance_courses
  AND p.sku IN (
    'C104',
    'C207',
    'C057',
    'C177',
    'C1164'
  );

-- ===== D: ai-for-healthcare-courses =====

SET @sc_ai_for_healthcare_courses := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-healthcare-courses' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @sc_ai_for_healthcare_courses, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @sc_ai_for_healthcare_courses IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C1018'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @sc_ai_for_healthcare_courses, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @sc_ai_for_healthcare_courses IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C1018'
  )
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C1018' THEN 101
END
WHERE cp.category_id = @sc_ai_for_healthcare_courses
  AND p.sku IN (
    'C1018'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C1018' THEN 101
END
WHERE i.category_id = @sc_ai_for_healthcare_courses
  AND p.sku IN (
    'C1018'
  );

-- ===== D: ai-for-hr =====

SET @sc_ai_for_hr := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-hr-courses' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @sc_ai_for_hr, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @sc_ai_for_hr IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C820'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @sc_ai_for_hr, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @sc_ai_for_hr IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C820'
  )
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C820' THEN 101
END
WHERE cp.category_id = @sc_ai_for_hr
  AND p.sku IN (
    'C820'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C820' THEN 101
END
WHERE i.category_id = @sc_ai_for_hr
  AND p.sku IN (
    'C820'
  );

-- ===== D: ai-for-machine-learning =====

SET @sc_ai_for_machine_learning := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-machine-learning' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @sc_ai_for_machine_learning, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @sc_ai_for_machine_learning IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C19',
    'C1330',
    'C279',
    'C476',
    'C1750'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @sc_ai_for_machine_learning, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @sc_ai_for_machine_learning IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C19',
    'C1330',
    'C279',
    'C476',
    'C1750'
  )
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C430' THEN 101
  WHEN 'C592' THEN 102
  WHEN 'C188' THEN 103
  WHEN 'C539' THEN 104
  WHEN 'C1071' THEN 105
  WHEN 'C926' THEN 106
  WHEN 'C1759' THEN 107
  WHEN 'C19' THEN 108
  WHEN 'C1330' THEN 109
  WHEN 'C279' THEN 110
  WHEN 'C476' THEN 111
  WHEN 'C1750' THEN 112
END
WHERE cp.category_id = @sc_ai_for_machine_learning
  AND p.sku IN (
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C19',
    'C1330',
    'C279',
    'C476',
    'C1750'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C430' THEN 101
  WHEN 'C592' THEN 102
  WHEN 'C188' THEN 103
  WHEN 'C539' THEN 104
  WHEN 'C1071' THEN 105
  WHEN 'C926' THEN 106
  WHEN 'C1759' THEN 107
  WHEN 'C19' THEN 108
  WHEN 'C1330' THEN 109
  WHEN 'C279' THEN 110
  WHEN 'C476' THEN 111
  WHEN 'C1750' THEN 112
END
WHERE i.category_id = @sc_ai_for_machine_learning
  AND p.sku IN (
    'C430',
    'C592',
    'C188',
    'C539',
    'C1071',
    'C926',
    'C1759',
    'C19',
    'C1330',
    'C279',
    'C476',
    'C1750'
  );

-- ===== D: ai-for-robotics =====

SET @sc_ai_for_robotics := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-robotics' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @sc_ai_for_robotics, p.entity_id, 9999
FROM catalog_product_entity p
WHERE @sc_ai_for_robotics IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C852'
  );

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @sc_ai_for_robotics, p.entity_id, 9999, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @sc_ai_for_robotics IS NOT NULL AND @is_sg > 0
  AND p.sku IN (
    'C852'
  )
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C852' THEN 101
END
WHERE cp.category_id = @sc_ai_for_robotics
  AND p.sku IN (
    'C852'
  );

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C852' THEN 101
END
WHERE i.category_id = @sc_ai_for_robotics
  AND p.sku IN (
    'C852'
  );

-- ===== E: curated-order exemption for every touched subcategory =====

UPDATE core_config_data
SET value = CONCAT(value, ',ai-for-business')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-for-business%';

UPDATE core_config_data
SET value = CONCAT(value, ',ai-for-finance-courses')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-for-finance-courses%';

UPDATE core_config_data
SET value = CONCAT(value, ',ai-for-healthcare-courses')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-for-healthcare-courses%';

UPDATE core_config_data
SET value = CONCAT(value, ',ai-for-hr-courses')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-for-hr-courses%';

UPDATE core_config_data
SET value = CONCAT(value, ',ai-for-machine-learning')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-for-machine-learning%';

UPDATE core_config_data
SET value = CONCAT(value, ',ai-for-robotics')
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND value NOT LIKE '%ai-for-robotics%';

