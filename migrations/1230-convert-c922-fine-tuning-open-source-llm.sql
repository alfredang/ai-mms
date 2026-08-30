-- 1230: Convert C922 "Deploy Jenkins with AI" into "Fine Tuning Open Source
-- LLM".
--
-- ("Fine Tunning" in the request is read as "Fine Tuning".)
--
-- SKU stays C922. New name, new url_key with a 301 from the old one, freshly
-- rendered branded R2 cover, new meta, a three-paragraph "What's This Course
-- About" and a rewritten "What You'll Learn" (4 topics).
--
-- It also leaves the RPA and DevOps trees, which no longer describe the
-- course. It keeps All Courses (3), Infocomm Technology (55), AI Courses
-- (252) and the AI Infrastructure Series (250) — where model training and
-- deployment belongs — and holds its pinned position there.
--
-- Its funding card (created by 1226 with the AI-Infrastructure/ML target) is
-- repointed at the far closer "WSQ - Generative AI Model Development and
-- Fine Tuning" (verified 200). Content-only UPDATE — never a cms/block model
-- save, which wipes the store mapping.
--
-- Course is 7.5h / 1 day; the copy reflects that. Topic HTML uses the
-- LSN_DATA + <h3 class="course-topic-h3"> shape the product page expects.
--
-- SG-guarded; C-prefix SKU and this url_key are SG-only (partner no-op).
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

SET @e922 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C922' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e922, 'Fine Tuning Open Source LLM'
FROM dual WHERE @e922 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e922 AND attribute_id = @a_pname AND store_id <> 0
  AND @e922 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e922, 'fine-tuning-open-source-llm'
FROM dual WHERE @e922 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e922 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e922 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e922, 'Fine Tuning Open Source LLM | Tertiary Courses Singapore'
FROM dual WHERE @e922 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e922, 'Fine-tune open source LLMs on your own data - dataset preparation, LoRA and QLoRA, training runs, evaluation and deployment of a private model you own.'
FROM dual WHERE @e922 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e922, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C922-20260830-081228.png'
FROM dual WHERE @e922 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) "What's This Course About" — three paragraphs.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e922,
'<p>Every prompt you send to a commercial AI model carries three costs: the per-token bill, the latency, and the fact that your data leaves your building. Fine tuning an open source LLM removes all three. Models like Llama, Mistral and Qwen are now strong enough that a well-tuned 7B or 8B model, trained on your own examples, will beat a general-purpose frontier model at your specific task &mdash; your tone, your terminology, your formats &mdash; while running on hardware you control.</p><p>In this hands-on 1-day course, you will take an open source model end to end: choosing the right base model for the job, building and cleaning a training dataset from your own documents and transcripts, and running efficient fine tunes with LoRA and QLoRA that train on a single GPU instead of a cluster. You will then evaluate the result honestly &mdash; measuring against the base model, watching for overfitting and catastrophic forgetting &mdash; and quantise and deploy the finished model behind an API you own.</p><p>You will leave with a fine-tuned model, a repeatable training pipeline and a clear-eyed view of when fine tuning is the right answer and when prompting or RAG would serve you better &mdash; the judgement that separates a working private model from an expensive experiment. Ideal for developers, data scientists, ML engineers and technical leads evaluating open source AI for production use.</p>'
FROM dual WHERE @e922 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 3) "What You'll Learn" — four topics.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e922,
'<!-- LSN_DATA: [{"title":"Topic 1 Open Source LLM Landscape","subsecs":[{"title":"Llama, Mistral, Qwen and the open model ecosystem","links":[]},{"title":"Model sizes, licences and hardware requirements","links":[]},{"title":"Fine tuning vs prompting vs RAG: choosing the right approach","links":[]},{"title":"Setting up your training environment","links":[]}]},{"title":"Topic 2 Preparing Your Training Data","subsecs":[{"title":"Building a dataset from your own documents and transcripts","links":[]},{"title":"Instruction, chat and completion formats","links":[]},{"title":"Cleaning, deduplication and train/test splits","links":[]},{"title":"How much data you actually need","links":[]}]},{"title":"Topic 3 Fine Tuning with LoRA and QLoRA","subsecs":[{"title":"Full fine tuning vs parameter-efficient methods","links":[]},{"title":"LoRA and QLoRA explained","links":[]},{"title":"Running a training job and reading the loss curves","links":[]},{"title":"Hyperparameters, overfitting and catastrophic forgetting","links":[]}]},{"title":"Topic 4 Evaluation and Deployment","subsecs":[{"title":"Evaluating against the base model","links":[]},{"title":"Quantisation for smaller, faster inference","links":[]},{"title":"Serving your model behind an API","links":[]},{"title":"Cost, privacy and maintenance in production","links":[]}]}] -->
<h3 class="course-topic-h3">Topic 1 Open Source LLM Landscape</h3>
<ul>
<li>Llama, Mistral, Qwen and the open model ecosystem</li>
<li>Model sizes, licences and hardware requirements</li>
<li>Fine tuning vs prompting vs RAG: choosing the right approach</li>
<li>Setting up your training environment</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Preparing Your Training Data</h3>
<ul>
<li>Building a dataset from your own documents and transcripts</li>
<li>Instruction, chat and completion formats</li>
<li>Cleaning, deduplication and train/test splits</li>
<li>How much data you actually need</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Fine Tuning with LoRA and QLoRA</h3>
<ul>
<li>Full fine tuning vs parameter-efficient methods</li>
<li>LoRA and QLoRA explained</li>
<li>Running a training job and reading the loss curves</li>
<li>Hyperparameters, overfitting and catastrophic forgetting</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Evaluation and Deployment</h3>
<ul>
<li>Evaluating against the base model</li>
<li>Quantisation for smaller, faster inference</li>
<li>Serving your model behind an API</li>
<li>Cost, privacy and maintenance in production</li>
</ul>'
FROM dual WHERE @e922 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e922 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e922 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 4) 301 the old URL, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'deploy-jenkins-with-ai.html' AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/c922-301', 'deploy-jenkins-with-ai.html', 'fine-tuning-open-source-llm.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e922) AND store_id = 1
  AND request_path <> 'fine-tuning-open-source-llm.html'
  AND @e922 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e922), 'fine-tuning-open-source-llm.html',
       CONCAT('catalog/product/view/id/', @e922), 1, @e922
FROM dual WHERE @e922 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 5) Leave the RPA and DevOps trees (AI Infrastructure Series is retained).
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e922
  AND cp.category_id IN (202, 304)
  AND @e922 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e922
  AND i.category_id IN (202, 304)
  AND @e922 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 6) Repoint its funding card at the matching WSQ course.
-- ---------------------------------------------------------------------------

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-model-development-and-fine-tuning.html" title="WSQ - Generative AI Model Development and Fine Tuning">WSQ - Generative AI Model Development and Fine Tuning</a></span></p>'
WHERE identifier = 'course_C922_funding_and_grant'
  AND @is_sg > 0;
