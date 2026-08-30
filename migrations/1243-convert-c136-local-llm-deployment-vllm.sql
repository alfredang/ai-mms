-- 1243: Convert C136 "AI Vibe Coding for Javascript" into "Local LLM
-- Deployment with vLLM", and move it from the AI Vibe Coding Series to the
-- AI Infrastructure Series.
--
-- SKU stays C136. New name, new url_key with a 301 from the old one, freshly
-- rendered branded R2 cover, new meta, plus a written-from-scratch
-- "What's This Course About" (three paragraphs) and "What You'll Learn"
-- (four topics) — no donor course was named. The subject pairs with C922
-- "Fine Tuning Open Source LLM": that course trains a model, this one serves
-- it, so it is placed immediately after C922 in the listing.
--
-- It also leaves the Web Development / Javascript trees, which no longer
-- describe the course (same treatment as the C28/C169/C178/C356 conversions).
-- It keeps All Courses (3), Infocomm Technology (55) and AI Courses (252).
--
-- The AI Infrastructure Series non-WSQ block is re-pinned with every member
-- covered so none drifts above it (see
-- feedback_curated_leftovers_must_be_pinned_not_parked). Positions stay in
-- the 101+ band, after every WSQ/CASL/IBF course.
--
-- Its funding card (created by 1226 with the AI Vibe Coding target) is
-- repointed at WSQ - Generative AI Model Development and Fine Tuning, the
-- closest funded course.
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

SET @e136 := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C136' LIMIT 1);

SET @vibe := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-vibe-coding-series' LIMIT 1);
SET @infra := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE v.attribute_id = @a_curlkey AND v.store_id = 0 AND v.value = 'ai-infrastructure-series' LIMIT 1);

-- ---------------------------------------------------------------------------
-- 1) Name, slug, meta, cover.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pname, 0, @e136, 'Local LLM Deployment with vLLM'
FROM dual WHERE @e136 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e136 AND attribute_id = @a_pname AND store_id <> 0
  AND @e136 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_purlkey, 0, @e136, 'local-llm-deployment-with-vllm'
FROM dual WHERE @e136 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e136 AND attribute_id = @a_purlkey AND store_id <> 0
  AND @e136 IS NOT NULL AND @is_sg > 0;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetat, 0, @e136, 'Local LLM Deployment with vLLM | Tertiary Courses Singapore'
FROM dual WHERE @e136 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pmetad, 0, @e136, 'Serve open source LLMs on your own hardware with vLLM - installation, OpenAI-compatible APIs, quantisation, throughput tuning and production deployment.'
FROM dual WHERE @e136 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pcimg, 0, @e136, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C136-20260830-123736.png'
FROM dual WHERE @e136 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 2) "What's This Course About" — three paragraphs.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_psdesc, 0, @e136,
'<p>Sending every request to a commercial AI API means paying per token, waiting on someone else''s latency, and shipping your data offsite. Running the model yourself removes all three &mdash; but a naive local deployment serves one request at a time and falls over the moment real traffic arrives. vLLM is the open source inference engine that closes that gap, using paged attention and continuous batching to serve open models at throughput that makes self-hosting genuinely practical.</p><p>In this hands-on 1-day course, you will stand up a local LLM deployment end to end: installing vLLM, loading models like Llama, Mistral and Qwen, and exposing them behind an OpenAI-compatible API so your existing code works unchanged. You will then make it perform &mdash; sizing GPU memory, applying quantisation to fit larger models on smaller cards, tuning batching and context length for your workload, and benchmarking honestly against what you are paying an API provider today.</p><p>You will leave with a running inference server, a tuned configuration and a clear cost-and-capacity picture for self-hosting &mdash; including where it genuinely wins and where a hosted API is still the better call. Ideal for developers, ML and platform engineers, and technical leads evaluating private or on-premise AI deployment.</p>'
FROM dual WHERE @e136 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------------------------------
-- 3) "What You'll Learn" — four topics.
-- ---------------------------------------------------------------------------

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_pdesc, 0, @e136,
'<!-- LSN_DATA: [{"title":"Topic 1 Why Self-Host an LLM","subsecs":[{"title":"Cost, latency and data privacy trade-offs","links":[]},{"title":"Hosted API vs local deployment: when each wins","links":[]},{"title":"Hardware and GPU requirements","links":[]},{"title":"How vLLM differs from a naive local setup","links":[]}]},{"title":"Topic 2 Getting Started with vLLM","subsecs":[{"title":"Installing and configuring vLLM","links":[]},{"title":"Loading open models: Llama, Mistral, Qwen","links":[]},{"title":"Serving an OpenAI-compatible API","links":[]},{"title":"Connecting existing applications with no code changes","links":[]}]},{"title":"Topic 3 Performance and Memory","subsecs":[{"title":"Paged attention and continuous batching explained","links":[]},{"title":"Sizing GPU memory for your model","links":[]},{"title":"Quantisation to fit larger models on smaller cards","links":[]},{"title":"Tuning batching, context length and throughput","links":[]}]},{"title":"Topic 4 Running It in Production","subsecs":[{"title":"Benchmarking against a hosted API","links":[]},{"title":"Monitoring, logging and health checks","links":[]},{"title":"Scaling, concurrency and failure handling","links":[]},{"title":"Cost modelling and ongoing maintenance","links":[]}]}] -->
<h3 class="course-topic-h3">Topic 1 Why Self-Host an LLM</h3>
<ul>
<li>Cost, latency and data privacy trade-offs</li>
<li>Hosted API vs local deployment: when each wins</li>
<li>Hardware and GPU requirements</li>
<li>How vLLM differs from a naive local setup</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Getting Started with vLLM</h3>
<ul>
<li>Installing and configuring vLLM</li>
<li>Loading open models: Llama, Mistral, Qwen</li>
<li>Serving an OpenAI-compatible API</li>
<li>Connecting existing applications with no code changes</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Performance and Memory</h3>
<ul>
<li>Paged attention and continuous batching explained</li>
<li>Sizing GPU memory for your model</li>
<li>Quantisation to fit larger models on smaller cards</li>
<li>Tuning batching, context length and throughput</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Running It in Production</h3>
<ul>
<li>Benchmarking against a hosted API</li>
<li>Monitoring, logging and health checks</li>
<li>Scaling, concurrency and failure handling</li>
<li>Cost modelling and ongoing maintenance</li>
</ul>'
FROM dual WHERE @e136 IS NOT NULL AND @is_sg > 0
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
WHERE entity_id = @e136 AND attribute_id IN (@a_pdesc, @a_psdesc) AND store_id <> 0
  AND @e136 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 4) 301 the old slug, seat the new system rewrite.
-- ---------------------------------------------------------------------------

DELETE FROM core_url_rewrite
WHERE request_path = 'ai-vibe-coding-for-javascript.html'
  AND store_id = 1
  AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, 'custom/ai-vibe-coding-for-javascript-301',
       'ai-vibe-coding-for-javascript.html', 'local-llm-deployment-with-vllm.html', 0, 'RP'
FROM dual WHERE @is_sg > 0;

DELETE FROM core_url_rewrite
WHERE id_path = CONCAT('product/', @e136) AND store_id = 1
  AND request_path <> 'local-llm-deployment-with-vllm.html'
  AND @e136 IS NOT NULL AND @is_sg > 0;

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, product_id)
SELECT 1, CONCAT('product/', @e136), 'local-llm-deployment-with-vllm.html',
       CONCAT('catalog/product/view/id/', @e136), 1, @e136
FROM dual WHERE @e136 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 5) Leave the AI Vibe Coding Series and the Web Development / Javascript
--    trees.
-- ---------------------------------------------------------------------------

DELETE cp FROM catalog_category_product cp
WHERE cp.product_id = @e136
  AND cp.category_id IN (@vibe, 4, 96)
  AND @e136 IS NOT NULL AND @is_sg > 0;

DELETE i FROM catalog_category_product_index i
WHERE i.product_id = @e136
  AND i.category_id IN (@vibe, 4, 96)
  AND @e136 IS NOT NULL AND @is_sg > 0;

-- ---------------------------------------------------------------------------
-- 6) Join the AI Infrastructure Series, right after Fine Tuning Open Source
--    LLM, and re-pin the whole non-WSQ block.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @infra, p.entity_id, 104
FROM catalog_product_entity p
WHERE @infra IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C136';

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @infra, p.entity_id, 104, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @infra IS NOT NULL AND @is_sg > 0
  AND p.sku = 'C136'
GROUP BY p.entity_id, s.store_id;

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C1285' THEN 101
  WHEN 'C742'  THEN 102
  WHEN 'C922'  THEN 103
  WHEN 'C136'  THEN 104
  WHEN 'C430'  THEN 105
  WHEN 'C592'  THEN 106
  WHEN 'C188'  THEN 107
  WHEN 'C539'  THEN 108
  WHEN 'C1071' THEN 109
  WHEN 'C926'  THEN 110
  WHEN 'C1759' THEN 111
  WHEN 'C1762' THEN 112
  WHEN 'C19'   THEN 113
  WHEN 'C1330' THEN 114
  WHEN 'C279'  THEN 115
END
WHERE cp.category_id = @infra
  AND p.sku IN ('C1285','C742','C922','C136','C430','C592','C188','C539',
                'C1071','C926','C1759','C1762','C19','C1330','C279');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C1285' THEN 101
  WHEN 'C742'  THEN 102
  WHEN 'C922'  THEN 103
  WHEN 'C136'  THEN 104
  WHEN 'C430'  THEN 105
  WHEN 'C592'  THEN 106
  WHEN 'C188'  THEN 107
  WHEN 'C539'  THEN 108
  WHEN 'C1071' THEN 109
  WHEN 'C926'  THEN 110
  WHEN 'C1759' THEN 111
  WHEN 'C1762' THEN 112
  WHEN 'C19'   THEN 113
  WHEN 'C1330' THEN 114
  WHEN 'C279'  THEN 115
END
WHERE i.category_id = @infra
  AND p.sku IN ('C1285','C742','C922','C136','C430','C592','C188','C539',
                'C1071','C926','C1759','C1762','C19','C1330','C279');

-- ---------------------------------------------------------------------------
-- 7) Repoint the funding card at the closest funded course.
-- ---------------------------------------------------------------------------

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-generative-ai-model-development-and-fine-tuning.html" title="WSQ - Generative AI Model Development and Fine Tuning">WSQ - Generative AI Model Development and Fine Tuning</a></span></p>'
WHERE identifier = 'course_C136_funding_and_grant'
  AND @is_sg > 0;
