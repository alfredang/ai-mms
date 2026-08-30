-- 1233: Fix the AI Applications Series subcategory pages.
--
-- TWO bugs, both from repurposing deactivated categories (1196/1204/1206/1211)
-- without replacing their editorial content:
--
-- (a) STALE PAGE CONTENT. Each repurposed category kept the description and
--     meta of the category it used to be, so the pages read as the old topic
--     under the new title:
--       AI for Educators     <- "Analog IC Design" copy
--       AI for Robotics      <- "eLearning Content Creation" copy
--       AI for HR            <- "Learning Management System (LMS)" copy
--       AI for Manufacturing <- "E-learning" copy
--       AI for STEM          <- "Cert Verify"
--       AI for Business      <- meta_title "AI for General Applications"
--     Every subcategory now gets a description, meta_title and
--     meta_description written for what it actually contains.
--
-- (b) BROKEN MENU DROPDOWN. Computer Vision (186) and Reinforcement Learning
--     (190) still sat at positions 1 and 2, colliding with AI for Business (1)
--     and AI for HR (2). Duplicate positions make the sort non-deterministic,
--     which is why the AI Applications flyout stopped rendering reliably.
--     The ten menu subcategories are renumbered 1..10 and the two hidden
--     legacy children are moved to 90/91, clear of the range.
--
-- Descriptions are plain two-paragraph copy in the same shape as the other
-- series landing pages. Content only - no membership or ordering changes.
--
-- SG-guarded; these url_keys are SG-only (partner no-op). Idempotent.

SET @is_sg := (
  SELECT COUNT(*) FROM core_config_data
  WHERE path = 'web/unsecure/base_url'
    AND value LIKE '%tertiarycourses.com.sg%'
);

SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_cdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');
SET @a_cmetat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');
SET @a_cmetad  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description');

SET @apps := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-applications-series' LIMIT 1);

SET @has_flat := (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1'
);

-- ===== AI for Business =====

SET @c_128 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-business' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_128 AND attribute_id IN (@a_cdesc, @a_cmetad) AND store_id <> 0
  AND @c_128 IS NOT NULL AND @is_sg > 0;

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_128 AND attribute_id = @a_cmetat AND store_id <> 0
  AND @c_128 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cdesc, 0, @c_128, '<p>Artificial intelligence has moved from the IT department into everyday business decisions. The <strong>AI for Business</strong> courses show managers, founders and business professionals how to put AI to work where it actually pays: spotting opportunities, transforming operations, developing products and lifting the productivity of ordinary office work.</p><p>Courses in this collection cover business innovation and transformation with AI, AI for product development, and applied AI across functions such as logistics, retail and early childhood education, alongside Microsoft''s AI business certifications. Most are hands-on and require no programming background.</p>' FROM dual WHERE @c_128 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetad, 0, @c_128, 'Practical AI courses for business - innovation, transformation, product development, logistics, retail and everyday productivity with AI tools and agents.' FROM dual WHERE @c_128 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetat, 0, @c_128, 'AI for Business Courses in Singapore | Tertiary Courses' FROM dual WHERE @c_128 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity SET position = 1
WHERE entity_id = @c_128 AND @c_128 IS NOT NULL AND @is_sg > 0;

-- ===== AI for HR =====

SET @c_378 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-hr-courses' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_378 AND attribute_id IN (@a_cdesc, @a_cmetad) AND store_id <> 0
  AND @c_378 IS NOT NULL AND @is_sg > 0;

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_378 AND attribute_id = @a_cmetat AND store_id <> 0
  AND @c_378 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cdesc, 0, @c_378, '<p>AI is reshaping what jobs look like and how HR teams do their work. The <strong>AI for HR</strong> courses help HR, L&amp;D and people leaders evaluate their workplace for AI readiness, redesign roles around new capabilities, and apply AI to recruitment, performance management and workforce planning.</p><p>Courses in this collection cover job assessment and redesign for AI adoption, workplace evaluation and innovation, and practical AI use in the HR function. They are designed for practitioners, not engineers, and focus on the decisions HR teams are being asked to make now.</p>' FROM dual WHERE @c_378 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetad, 0, @c_378, 'AI courses for HR and people teams - job redesign, workplace evaluation for AI adoption, and applying AI across recruitment, performance and workforce planning.' FROM dual WHERE @c_378 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetat, 0, @c_378, 'AI for HR Courses in Singapore | Tertiary Courses' FROM dual WHERE @c_378 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity SET position = 2
WHERE entity_id = @c_378 AND @c_378 IS NOT NULL AND @is_sg > 0;

-- ===== AI for Finance =====

SET @c_230 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-finance-courses' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_230 AND attribute_id IN (@a_cdesc, @a_cmetad) AND store_id <> 0
  AND @c_230 IS NOT NULL AND @is_sg > 0;

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_230 AND attribute_id = @a_cmetat AND store_id <> 0
  AND @c_230 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cdesc, 0, @c_230, '<p>Finance was among the first industries to adopt machine learning at scale, and the tooling has now reached accountants, analysts and independent traders. The <strong>AI for Finance</strong> courses cover applied AI across the finance function - from automating accounting workflows to building and testing trading strategies.</p><p>Courses in this collection include generative AI for finance and fintech, AI for accounting, agentic AI for finance, AI agents for trading, and IBF-funded programmes in financial data mining, machine learning for trading and deep learning for financial services.</p>' FROM dual WHERE @c_230 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetad, 0, @c_230, 'AI and machine learning courses for finance - accounting automation, financial analysis, algorithmic trading, fintech and IBF-funded programmes.' FROM dual WHERE @c_230 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetat, 0, @c_230, 'AI for Finance Courses in Singapore | Tertiary Courses' FROM dual WHERE @c_230 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity SET position = 3
WHERE entity_id = @c_230 AND @c_230 IS NOT NULL AND @is_sg > 0;

-- ===== AI for Healthcare =====

SET @c_235 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-healthcare-courses' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_235 AND attribute_id IN (@a_cdesc, @a_cmetad) AND store_id <> 0
  AND @c_235 IS NOT NULL AND @is_sg > 0;

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_235 AND attribute_id = @a_cmetat AND store_id <> 0
  AND @c_235 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cdesc, 0, @c_235, '<p>Healthcare generates enormous volumes of data, and AI is increasingly used to turn it into better clinical and operational decisions. The <strong>AI for Healthcare</strong> courses introduce data analytics and AI techniques in a healthcare context, with attention to the accuracy, privacy and governance requirements the sector demands.</p><p>Courses in this collection are suitable for healthcare professionals, administrators and analysts who want to understand what AI can realistically do in a clinical or operational setting.</p>' FROM dual WHERE @c_235 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetad, 0, @c_235, 'AI and data analytics courses for healthcare - clinical data analysis, healthcare operations and applying AI responsibly in medical settings.' FROM dual WHERE @c_235 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetat, 0, @c_235, 'AI for Healthcare Courses in Singapore | Tertiary Courses' FROM dual WHERE @c_235 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity SET position = 4
WHERE entity_id = @c_235 AND @c_235 IS NOT NULL AND @is_sg > 0;

-- ===== AI for Robotics =====

SET @c_377 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-robotics' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_377 AND attribute_id IN (@a_cdesc, @a_cmetad) AND store_id <> 0
  AND @c_377 IS NOT NULL AND @is_sg > 0;

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_377 AND attribute_id = @a_cmetat AND store_id <> 0
  AND @c_377 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cdesc, 0, @c_377, '<p>Robotics and connected devices are where AI meets the physical world. The <strong>AI for Robotics</strong> courses cover applying artificial intelligence to robotics, IoT and automated physical systems, including how agentic AI can monitor, decide and act on sensor data.</p><p>Courses in this collection suit engineers, technologists and makers who want to add intelligence to hardware and automated systems.</p>' FROM dual WHERE @c_377 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetad, 0, @c_377, 'AI courses for robotics and IoT - intelligent automation, connected devices and applying agentic AI to physical systems.' FROM dual WHERE @c_377 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetat, 0, @c_377, 'AI for Robotics Courses in Singapore | Tertiary Courses' FROM dual WHERE @c_377 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity SET position = 5
WHERE entity_id = @c_377 AND @c_377 IS NOT NULL AND @is_sg > 0;

-- ===== AI for Manufacturing =====

SET @c_299 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-manufacturing' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_299 AND attribute_id IN (@a_cdesc, @a_cmetad) AND store_id <> 0
  AND @c_299 IS NOT NULL AND @is_sg > 0;

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_299 AND attribute_id = @a_cmetat AND store_id <> 0
  AND @c_299 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cdesc, 0, @c_299, '<p>Manufacturing and supply chain operations run on data that has historically gone unused. The <strong>AI for Manufacturing</strong> courses cover applying AI to production and logistics - forecasting demand, optimising routes and schedules, and using machine learning to anticipate problems before they stop the line.</p><p>Courses in this collection suit operations managers, engineers and supply chain professionals looking for practical, applied uses of AI in industrial settings.</p>' FROM dual WHERE @c_299 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetad, 0, @c_299, 'AI courses for manufacturing and supply chain - predictive maintenance, quality inspection, logistics optimisation and smart factory operations.' FROM dual WHERE @c_299 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetat, 0, @c_299, 'AI for Manufacturing Courses in Singapore | Tertiary Courses' FROM dual WHERE @c_299 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity SET position = 6
WHERE entity_id = @c_299 AND @c_299 IS NOT NULL AND @is_sg > 0;

-- ===== AI for Retail =====

SET @c_436 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-retail-courses' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_436 AND attribute_id IN (@a_cdesc, @a_cmetad) AND store_id <> 0
  AND @c_436 IS NOT NULL AND @is_sg > 0;

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_436 AND attribute_id = @a_cmetat AND store_id <> 0
  AND @c_436 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cdesc, 0, @c_436, '<p>Retail runs on understanding customers faster than competitors do, and AI has become the tool that makes that possible at scale. The <strong>AI for Retail</strong> courses cover applying artificial intelligence across the retail and e-commerce value chain - personalisation, demand forecasting, customer analytics and merchandising.</p><p>Courses in this collection suit retail managers, e-commerce operators and marketing professionals who want practical AI skills they can apply to their own product and customer data.</p>' FROM dual WHERE @c_436 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetad, 0, @c_436, 'AI courses for retail and e-commerce - personalisation, demand forecasting, customer analytics and AI-driven merchandising and marketing.' FROM dual WHERE @c_436 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetat, 0, @c_436, 'AI for Retail Courses in Singapore | Tertiary Courses' FROM dual WHERE @c_436 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity SET position = 7
WHERE entity_id = @c_436 AND @c_436 IS NOT NULL AND @is_sg > 0;

-- ===== AI for Educators =====

SET @c_374 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-educators' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_374 AND attribute_id IN (@a_cdesc, @a_cmetad) AND store_id <> 0
  AND @c_374 IS NOT NULL AND @is_sg > 0;

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_374 AND attribute_id = @a_cmetat AND store_id <> 0
  AND @c_374 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cdesc, 0, @c_374, '<p>Teaching and training are being reshaped by generative AI, both as a subject and as a tool. The <strong>AI for Educators</strong> courses help teachers, trainers, curriculum leads and instructional designers use AI to plan, build and refine learning experiences without losing pedagogical rigour.</p><p>Courses in this collection cover generative AI for curriculum development and instructional design, showing how to draft, structure and iterate learning materials with AI assistance while keeping learning outcomes at the centre.</p>' FROM dual WHERE @c_374 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetad, 0, @c_374, 'AI courses for educators and trainers - curriculum development, instructional design, assessment and using generative AI in teaching and learning.' FROM dual WHERE @c_374 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetat, 0, @c_374, 'AI for Educators Courses in Singapore | Tertiary Courses' FROM dual WHERE @c_374 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity SET position = 8
WHERE entity_id = @c_374 AND @c_374 IS NOT NULL AND @is_sg > 0;

-- ===== AI for STEM =====

SET @c_262 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-stem' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_262 AND attribute_id IN (@a_cdesc, @a_cmetad) AND store_id <> 0
  AND @c_262 IS NOT NULL AND @is_sg > 0;

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_262 AND attribute_id = @a_cmetat AND store_id <> 0
  AND @c_262 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cdesc, 0, @c_262, '<p>The <strong>AI for STEM</strong> courses bring artificial intelligence into science, technology, engineering and mathematics - both as a tool for solving STEM problems and as a subject to teach.</p><p>Courses in this collection are aimed at STEM educators, students and practitioners who want to apply AI to experiments, modelling, data analysis and project work.</p>' FROM dual WHERE @c_262 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetad, 0, @c_262, 'AI courses for STEM education and practice - applying artificial intelligence to science, technology, engineering and mathematics teaching and projects.' FROM dual WHERE @c_262 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetat, 0, @c_262, 'AI for STEM Courses in Singapore | Tertiary Courses' FROM dual WHERE @c_262 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity SET position = 9
WHERE entity_id = @c_262 AND @c_262 IS NOT NULL AND @is_sg > 0;

-- ===== AI for Machine Learning =====

SET @c_245 := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-machine-learning' LIMIT 1);

DELETE FROM catalog_category_entity_text
WHERE entity_id = @c_245 AND attribute_id IN (@a_cdesc, @a_cmetad) AND store_id <> 0
  AND @c_245 IS NOT NULL AND @is_sg > 0;

DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @c_245 AND attribute_id = @a_cmetat AND store_id <> 0
  AND @c_245 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cdesc, 0, @c_245, '<p>Machine learning is the engine underneath most of what people call AI. The <strong>AI for Machine Learning</strong> courses run from fundamentals through to production - data mining, model building, deep learning with PyTorch, computer vision and reinforcement learning.</p><p>Courses in this collection also cover the major cloud certifications, including Microsoft Azure AI and AWS machine learning credentials, alongside AI vibe coding courses that build models with AI-assisted development tools.</p>' FROM dual WHERE @c_245 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetad, 0, @c_245, 'Machine learning and deep learning courses - Python, PyTorch, computer vision, plus Microsoft Azure AI and AWS machine learning certifications.' FROM dual WHERE @c_245 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_cmetat, 0, @c_245, 'AI for Machine Learning Courses in Singapore | Tertiary Courses' FROM dual WHERE @c_245 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_category_entity SET position = 10
WHERE entity_id = @c_245 AND @c_245 IS NOT NULL AND @is_sg > 0;

-- ===== Legacy hidden children: clear of the 1..10 menu range =====

UPDATE catalog_category_entity e
JOIN catalog_category_entity_varchar v
  ON v.entity_id = e.entity_id AND v.attribute_id = @a_curlkey AND v.store_id = 0
SET e.position = CASE v.value
  WHEN 'deep-learning-computer-vision-courses' THEN 90
  WHEN 'deep-reinforcement-learning-courses'   THEN 91
END
WHERE e.parent_id = @apps
  AND v.value IN ('deep-learning-computer-vision-courses', 'deep-reinforcement-learning-courses')
  AND @is_sg > 0;

-- Mirror names/positions into the flat table so the menu and pages pick the
-- change up without waiting for a reindex. Guarded; 'DO 0' no-op.
SET @sql := IF(@has_flat > 0 AND @apps IS NOT NULL,
  'UPDATE catalog_category_flat_store_1 f JOIN catalog_category_entity e ON e.entity_id = f.entity_id SET f.position = e.position WHERE e.parent_id = @apps',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

