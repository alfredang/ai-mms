-- 1236: Finish the AI Applications subcategory repurpose cleanup.
--
-- Two more attributes carried over from the categories these were repurposed
-- from, both missed by 1233:
--
-- (a) umm_cat_target on AI for STEM (was "Cert Verify") still pointed at
--     'blockchain-certification.html'. The Infortis mega-menu renders that
--     attribute INSTEAD of the category's own URL, so clicking "AI for STEM"
--     in the dropdown landed on the Blockchain Certification page — the
--     category page itself was fine. See feedback_megamenu_umm_cat_target.
--     Cleared so the menu item resolves to /ai-for-stem.html.
--
-- (b) meta_keywords on all ten subcategories still described the old topic
--     ("Analog IC Design" under AI for Educators, "Google Tag Manager" under
--     AI for Healthcare, "Cert Verify" under AI for STEM, and so on). Each
--     now gets keywords for what it actually contains.
--
-- Store-scoped rows are deleted first so no override outranks the store-0
-- value. Content only — no membership, ordering or URL changes.
--
-- SG-guarded; these url_keys are SG-only (partner no-op). Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_ummtgt  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'umm_cat_target');
SET @a_ckw     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_keywords');

-- ===== (a) Clear the stale mega-menu link override on AI for STEM =====

SET @stem := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-stem' LIMIT 1);

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @stem
  AND attribute_id = @a_ummtgt
  AND @stem IS NOT NULL AND @is_sg > 0;

-- Defensive: no other AI Applications subcategory should carry a link
-- override either (none does today, but a future repurpose might).
DELETE v FROM catalog_category_entity_varchar v
JOIN catalog_category_entity e ON e.entity_id = v.entity_id
JOIN catalog_category_entity_varchar pk
  ON pk.entity_id = e.parent_id AND pk.attribute_id = @a_curlkey AND pk.store_id = 0
WHERE v.attribute_id = @a_ummtgt
  AND pk.value = 'ai-applications-series'
  AND @is_sg > 0;

-- ===== (b) Replace the stale meta_keywords =====

SET @c_ai_for_business := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-business' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_ai_for_business AND attribute_id = @a_ckw AND store_id <> 0
  AND @c_ai_for_business IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_ckw, 0, @c_ai_for_business, 'AI for business, business innovation with AI, AI transformation, AI for product development, AI business courses Singapore' FROM dual WHERE @c_ai_for_business IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @c_ai_for_hr_courses := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-hr-courses' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_ai_for_hr_courses AND attribute_id = @a_ckw AND store_id <> 0
  AND @c_ai_for_hr_courses IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_ckw, 0, @c_ai_for_hr_courses, 'AI for HR, job redesign, workplace AI adoption, HR analytics, AI recruitment, people analytics Singapore' FROM dual WHERE @c_ai_for_hr_courses IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @c_ai_for_finance_courses := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-finance-courses' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_ai_for_finance_courses AND attribute_id = @a_ckw AND store_id <> 0
  AND @c_ai_for_finance_courses IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_ckw, 0, @c_ai_for_finance_courses, 'AI for finance, AI accounting, algorithmic trading, fintech AI, financial data analytics Singapore' FROM dual WHERE @c_ai_for_finance_courses IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @c_ai_for_healthcare_courses := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-healthcare-courses' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_ai_for_healthcare_courses AND attribute_id = @a_ckw AND store_id <> 0
  AND @c_ai_for_healthcare_courses IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_ckw, 0, @c_ai_for_healthcare_courses, 'AI for healthcare, clinical data analytics, healthcare AI, medical data analysis Singapore' FROM dual WHERE @c_ai_for_healthcare_courses IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @c_ai_for_robotics := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-robotics' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_ai_for_robotics AND attribute_id = @a_ckw AND store_id <> 0
  AND @c_ai_for_robotics IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_ckw, 0, @c_ai_for_robotics, 'AI for robotics, robotics AI, IoT AI, intelligent automation, agentic AI robotics Singapore' FROM dual WHERE @c_ai_for_robotics IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @c_ai_for_manufacturing := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-manufacturing' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_ai_for_manufacturing AND attribute_id = @a_ckw AND store_id <> 0
  AND @c_ai_for_manufacturing IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_ckw, 0, @c_ai_for_manufacturing, 'AI for manufacturing, smart factory, predictive maintenance, supply chain AI, industrial AI Singapore' FROM dual WHERE @c_ai_for_manufacturing IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @c_ai_for_retail_courses := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-retail-courses' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_ai_for_retail_courses AND attribute_id = @a_ckw AND store_id <> 0
  AND @c_ai_for_retail_courses IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_ckw, 0, @c_ai_for_retail_courses, 'AI for retail, e-commerce AI, personalisation, demand forecasting, customer analytics Singapore' FROM dual WHERE @c_ai_for_retail_courses IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @c_ai_for_educators := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-educators' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_ai_for_educators AND attribute_id = @a_ckw AND store_id <> 0
  AND @c_ai_for_educators IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_ckw, 0, @c_ai_for_educators, 'AI for educators, AI in education, curriculum development, instructional design, generative AI teaching Singapore' FROM dual WHERE @c_ai_for_educators IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @c_ai_for_stem := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-stem' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_ai_for_stem AND attribute_id = @a_ckw AND store_id <> 0
  AND @c_ai_for_stem IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_ckw, 0, @c_ai_for_stem, 'AI for STEM, STEM education, AI in science, AI engineering, AI mathematics, STEM AI courses Singapore' FROM dual WHERE @c_ai_for_stem IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

SET @c_ai_for_machine_learning := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-machine-learning' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_ai_for_machine_learning AND attribute_id = @a_ckw AND store_id <> 0
  AND @c_ai_for_machine_learning IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_ckw, 0, @c_ai_for_machine_learning, 'machine learning, deep learning, PyTorch, computer vision, Azure AI, AWS machine learning, ML courses Singapore' FROM dual WHERE @c_ai_for_machine_learning IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Flat mirror (store 1), guarded; 'DO 0' no-op. umm_cat_target lives in the
-- flat table, so the menu keeps rendering the stale link until this is
-- cleared there too.
SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1'
);

SET @has_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'catalog_category_flat_store_1'
    AND COLUMN_NAME = 'umm_cat_target'
);

SET @sql := IF(@has_flat > 0 AND @has_col > 0 AND @stem IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 SET umm_cat_target = NULL WHERE entity_id = @stem',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

