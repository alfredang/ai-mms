-- 1257: AI Infrastructure Series — replace the stale AI DevOps write-up.
--
-- Category 250 was repurposed to "AI Infrastructure Series" but kept the old
-- AI DevOps Series description + meta_description (Docker/Jenkins/Kubernetes
-- copy), so the page described a toolchain the 28 courses no longer centre on.
-- See [[feedback_repurposed_category_keeps_old_content_and_position]].
--
-- New copy is grounded in the actual catalogue: model training and machine
-- learning (PyTorch, computer vision, reinforcement learning), LLM fine tuning
-- and local inference (Fine Tuning Open Source LLM, vLLM, GenAI Model
-- Development and Fine Tuning), MLOps and deployment (AI-300 ML Operations
-- Engineer, Docker/Kubernetes with AI), and the cloud AI/ML certification
-- tracks (Azure AI-900/AI-102/DP-100, AWS AI Practitioner / ML Engineer /
-- ML Specialty, Google Professional ML Engineer).
--
-- Also removes the duplicate meta_description row (a leftover "AI digital
-- human" value from an earlier repurpose) so only one canonical row remains.
--
-- Business-key lookup on url_key -> clean no-op on partner sites lacking the
-- category. EAV-only (Option A per the category-ordering skill): the storefront
-- picks this up on the Category Flat Data reindex. Idempotent.

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-infrastructure-series' LIMIT 1
);

SET @a_desc := (SELECT attribute_id FROM eav_attribute
  WHERE entity_type_id = 3 AND attribute_code = 'description');
SET @a_metad := (SELECT attribute_id FROM eav_attribute
  WHERE entity_type_id = 3 AND attribute_code = 'meta_description');

SET @desc := CONCAT(
'<p>Build the infrastructure that puts AI into production with our AI ',
'Infrastructure Series. These hands-on courses cover the full lifecycle - ',
'training machine learning models, fine tuning large language models, ',
'optimising inference, and deploying and operating it all reliably at scale.</p>',
'<p>You will work with PyTorch and modern ML frameworks, fine tune open source ',
'LLMs on your own data, serve models efficiently with vLLM and local ',
'deployment, and apply MLOps practices to containerise, orchestrate and ',
'monitor AI workloads in production. The series also spans the major cloud AI ',
'and machine learning certification tracks across Microsoft Azure, AWS and ',
'Google Cloud. Ideal for machine learning engineers, data scientists, MLOps ',
'and platform engineers who want to take AI models from notebook to ',
'production.</p>'
);

SET @metad := CONCAT(
'Hands-on AI infrastructure courses in Singapore - LLM fine tuning, MLOps, ',
'inference optimisation and machine learning, with Azure, AWS and Google ',
'Cloud AI certification tracks.'
);

-- ===== description (store 0 default scope) =====

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_desc, 0, @cat, @desc FROM dual
WHERE @cat IS NOT NULL AND @a_desc IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM catalog_category_entity_text) t
    WHERE t.entity_id = @cat AND t.attribute_id = @a_desc AND t.store_id = 0
  );

UPDATE catalog_category_entity_text
SET value = @desc
WHERE @cat IS NOT NULL AND @a_desc IS NOT NULL
  AND entity_id = @cat AND attribute_id = @a_desc AND store_id = 0;

-- ===== meta_description: collapse to ONE canonical store-0 row =====

DELETE FROM catalog_category_entity_text
WHERE @cat IS NOT NULL AND @a_metad IS NOT NULL
  AND entity_id = @cat AND attribute_id = @a_metad AND store_id = 0;

DELETE FROM catalog_category_entity_varchar
WHERE @cat IS NOT NULL AND @a_metad IS NOT NULL
  AND entity_id = @cat AND attribute_id = @a_metad AND store_id = 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metad, 0, @cat, @metad FROM dual
WHERE @cat IS NOT NULL AND @a_metad IS NOT NULL;
