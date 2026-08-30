-- 1244: Convert C1074 "AI Vibe Coding for Mobile Apps" into "Fine Tuning
-- OpenVLA Model", and move it from the AI Vibe Coding Series to AI for
-- Robotics.
--
-- SKU stays C1074. New name, new url_key with a 301 from the old one, freshly
-- rendered branded R2 cover, new meta, plus a written-from-scratch
-- "What's This Course About" (three paragraphs) and "What You'll Learn"
-- (four topics) — no donor course was named.
--
-- OpenVLA is an open vision-language-action model for robot control, so
-- AI for Robotics is the right home; it becomes that subcategory's second
-- course after "Agentic AI for IoT".
--
-- It also leaves the Mobile Apps / iOS / Android / Cross Platforms trees,
-- which no longer describe the course (same treatment as the previous
-- conversions). It keeps All Courses (3), Infocomm Technology (55) and AI
-- Courses (252).
--
-- Its funding card (created by 1226 with the AI Vibe Coding target) is
-- repointed at WSQ - Generative AI Model Development and Fine Tuning, the
-- closest funded course by subject.
--
-- Course is 7.5h / 1 day; the copy reflects that. Topic HTML uses the
-- LSN_DATA + <h3 class="course-topic-h3"> shape the product page expects.
-- The 301 uses a slug-derived id_path so a future rename cannot collide.
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
SET @a_pdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_psdesc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_pcimg   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');
SET @a_curlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');

SET @e1074 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1074' LIMIT 1);

SET @vibe := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1);
SET @robotics := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-for-robotics' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e1074, 'Fine Tuning OpenVLA Model'
FROM dual WHERE @e1074 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e1074 AND attribute_id = @a_pname AND store_id <> 0
  AND @e1074 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e1074, 'fine-tuning-openvla-model'
FROM dual WHERE @e1074 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e1074 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e1074 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e1074, 'Fine Tuning OpenVLA Model | Tertiary Courses Singapore'
FROM dual WHERE @e1074 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e1074, 'Fine-tune the OpenVLA vision-language-action model for your own robot - demonstration data, LoRA training, evaluation and deployment on real hardware.'
FROM dual WHERE @e1074 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e1074, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1074-20260830-125842.png'
FROM dual WHERE @e1074 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) "What's This Course About" — three paragraphs.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e1074,
'<p>Robotics has had its own foundation-model moment. Vision-language-action models take a camera feed and a plain-language instruction &mdash; "pick up the red block and put it in the bin" &mdash; and output robot actions directly, without the hand-written perception and control stack that used to sit in between. OpenVLA is the leading open model of this kind, and because it is open you can fine-tune it on your own robot, your own gripper and your own tasks rather than accepting whatever it learned in the lab.</p><p>In this hands-on 1-day course, you will take OpenVLA end to end: understanding how a VLA model turns pixels and language into actions, collecting and formatting demonstration data for your own setup, and running efficient LoRA fine-tunes that train on a single GPU. You will then evaluate the result properly &mdash; success rates on held-out tasks, failure-mode analysis, and the sim-to-real gap &mdash; before deploying the tuned policy onto hardware with the safety limits any real robot needs.</p><p>You will leave with a fine-tuned VLA policy, a reusable data-collection and training pipeline, and a realistic sense of what these models can and cannot do today. Ideal for robotics engineers, ML practitioners, researchers and technically-minded makers who want to move from scripted robot behaviour to learned, instruction-following control.</p>'
FROM dual WHERE @e1074 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 3) "What You'll Learn" — four topics.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e1074,
'<!-- LSN_DATA: [{"title":"Topic 1 Vision-Language-Action Models","subsecs":[{"title":"From scripted control to learned robot policies","links":[]},{"title":"How VLA models map pixels and language to actions","links":[]},{"title":"The OpenVLA architecture and what it was trained on","links":[]},{"title":"Hardware, GPU and robot requirements","links":[]}]},{"title":"Topic 2 Collecting and Preparing Demonstration Data","subsecs":[{"title":"Teleoperation and demonstration capture","links":[]},{"title":"Episode formats, action spaces and camera setup","links":[]},{"title":"Cleaning, augmenting and splitting your dataset","links":[]},{"title":"How many demonstrations a task really needs","links":[]}]},{"title":"Topic 3 Fine Tuning OpenVLA","subsecs":[{"title":"Setting up the training environment","links":[]},{"title":"LoRA fine tuning on a single GPU","links":[]},{"title":"Hyperparameters, loss curves and overfitting","links":[]},{"title":"Adapting the model to your gripper and workspace","links":[]}]},{"title":"Topic 4 Evaluation and Deployment","subsecs":[{"title":"Measuring success rates on held-out tasks","links":[]},{"title":"Failure-mode analysis and the sim-to-real gap","links":[]},{"title":"Running inference on the robot","links":[]},{"title":"Safety limits, monitoring and iteration","links":[]}]}] -->
<h3 class="course-topic-h3">Topic 1 Vision-Language-Action Models</h3>
<ul>
<li>From scripted control to learned robot policies</li>
<li>How VLA models map pixels and language to actions</li>
<li>The OpenVLA architecture and what it was trained on</li>
<li>Hardware, GPU and robot requirements</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Collecting and Preparing Demonstration Data</h3>
<ul>
<li>Teleoperation and demonstration capture</li>
<li>Episode formats, action spaces and camera setup</li>
<li>Cleaning, augmenting and splitting your dataset</li>
<li>How many demonstrations a task really needs</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Fine Tuning OpenVLA</h3>
<ul>
<li>Setting up the training environment</li>
<li>LoRA fine tuning on a single GPU</li>
<li>Hyperparameters, loss curves and overfitting</li>
<li>Adapting the model to your gripper and workspace</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Evaluation and Deployment</h3>
<ul>
<li>Measuring success rates on held-out tasks</li>
<li>Failure-mode analysis and the sim-to-real gap</li>
<li>Running inference on the robot</li>
<li>Safety limits, monitoring and iteration</li>
</ul>'
FROM dual WHERE @e1074 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e1074 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e1074 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 4) 301 the old slug, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-vibe-coding-for-mobile-apps-development.html'
  AND store_id = 1
  AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/ai-vibe-coding-for-mobile-apps-development-301',
       'ai-vibe-coding-for-mobile-apps-development.html', 'fine-tuning-openvla-model.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e1074) AND store_id = 1
  AND request_path <> 'fine-tuning-openvla-model.html'
  AND @e1074 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e1074), 'fine-tuning-openvla-model.html',
       CONCAT('catalog/product/view/id/', @e1074), 1, @e1074
FROM dual WHERE @e1074 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 5) Leave the AI Vibe Coding Series and the Mobile Apps trees.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e1074
  AND cp.category_id IN (@vibe, 50, 77, 78, 249)
  AND @e1074 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e1074
  AND i.category_id IN (@vibe, 50, 77, 78, 249)
  AND @e1074 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 6) Join AI for Robotics, after "Agentic AI for IoT".
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @robotics, p.entity_id, 102
FROM catalog_product_entity p
WHERE @robotics IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C1074';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @robotics, p.entity_id, 102, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @robotics IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C1074'
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku WHEN 'C852' THEN 101 WHEN 'C1074' THEN 102 END
WHERE cp.category_id = @robotics
  AND p.sku IN ('C852', 'C1074');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku WHEN 'C852' THEN 101 WHEN 'C1074' THEN 102 END
WHERE i.category_id = @robotics
  AND p.sku IN ('C852', 'C1074');

-- ---------------------------------------------------------------------------
-- 7) Repoint the funding card at the closest funded course.
-- ---------------------------------------------------------------------------

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-model-development-and-fine-tuning.html" title="WSQ - Generative AI Model Development and Fine Tuning">WSQ - Generative AI Model Development and Fine Tuning</a></span></p>'
WHERE identifier = 'course_C1074_funding_and_grant'
  AND @is_sg > 0;
