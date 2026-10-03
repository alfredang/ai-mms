-- C1762: "AI-300 Microsoft Certified Machine Learning Operations Engineer Associate" ->
-- "AI-300 Microsoft Certified Machine Learning Operations Engineer Associate Exam Prep".
-- Originally-authored non-WSQ course (no WSQ twin; funding block says no funding).
--
-- PROBED on prod before writing (entity 1762):
--   * duration 37.5 / sessions 5 / price 1800 (store 0 only, no store override), template E03.
--   * media-gallery label still read the previous life's "MB-820 ... Business Central Developer".
--   * one catalogsearch_query row redirects to the old slug.
--
-- 1. name, url_key/url_path (... -associate -> ... -associate-exam-prep), cover alt/gallery labels,
--    meta title/description/keywords.
-- 2. 4 days: duration 37.5 -> 30, sessions 5 -> 4; course fee $1,800 -> $1,400 (every scope row).
-- 3. About opener names the new title; topics follow the five AI-300 exam domains and their
--    skills-measured sub-sections (study guide, skills measured as of Feb 2026).
-- 4. 301s: system rows renamed in place; every old path 301s one hop to the new bare slug.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): refreshProductRewrite, schedule template E03 -> D03 (code path),
-- cover re-render (the PNG bakes the title), price + flat reindex, flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1762' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @new_title := 'AI-300 Microsoft Certified Machine Learning Operations Engineer Associate Exam Prep';
SET @old_slug  := 'ai-300-microsoft-certified-machine-learning-operations-engineer-associate';
SET @new_slug  := 'ai-300-microsoft-certified-machine-learning-operations-engineer-associate-exam-prep';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_price   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');

-- ------------------------------------------------------- name / slug -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @pid, @new_title FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_urlkey, 0, @pid, @new_slug FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

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

-- ------------------------------------------- fee / duration / sessions -----
INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @pid, 1400 FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_decimal SET value = 1400
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '30' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '4' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'AI-300 Microsoft Certified Machine Learning Operations Engineer Associate Exam Prep in Singapore: MLOps with Azure Machine Learning and GenAIOps with Microsoft Foundry, GitHub Actions and Bicep.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'AI-300 Microsoft Certified Machine Learning Operations Engineer Associate Exam Prep, AI-300, AI-300 exam prep, MLOps, GenAIOps, Azure Machine Learning, Microsoft Foundry, MLflow, GitHub Actions, Bicep, RAG, fine-tuning, Microsoft Certification, Tertiary Courses'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid
   AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_urlkey, @a_urlpath, @a_dur, @a_sess) AND store_id <> 0;
DELETE FROM catalog_product_entity_decimal
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price AND store_id <> 0;

-- ------------------------------------------------- About + exam topics ----
UPDATE catalog_product_entity_text
   SET value = REPLACE(value,
       'The AI-300 Microsoft Certified Machine Learning Operations Engineer Associate course equips',
       'The AI-300 Microsoft Certified Machine Learning Operations Engineer Associate Exam Prep course equips')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_short AND store_id = 0
   AND value NOT LIKE '%Associate Exam Prep course equips%';

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<p>This exam prep course follows the official <strong>AI-300: Operationalizing Machine Learning and Generative AI Solutions</strong> skills measured, domain by domain:</p>
<h3 class="course-topic-h3">Topic 1 Design and Implement an MLOps Infrastructure (15-20%)</h3>
<ul>
<li>Create and manage resources in a Machine Learning workspace: workspaces, datastores, compute targets, identity and access management</li>
<li>Create and manage assets: data assets, environments, components, and sharing assets across workspaces with registries</li>
<li>Implement infrastructure as code: GitHub integration, Bicep and Azure CLI deployments, GitHub Actions provisioning workflows</li>
<li>Restrict network access to Machine Learning workspaces and manage source control for ML projects with Git</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Implement Machine Learning Model Lifecycle and Operations (25-30%)</h3>
<ul>
<li>Orchestrate model training: MLflow experiment tracking, automated ML, notebooks, hyperparameter tuning, training scripts, distributed training and training pipelines</li>
<li>Implement model registration and versioning: feature retrieval specifications, MLflow models, responsible AI evaluation and model lifecycle archiving</li>
<li>Deploy models for production: real-time and batch endpoints, endpoint testing and troubleshooting, progressive rollout and safe rollback</li>
<li>Monitor and maintain models in production: data drift, performance metrics, retraining and alert triggers</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Design and Implement a GenAIOps Infrastructure (20-25%)</h3>
<ul>
<li>Implement Foundry environments: resources and projects, managed identities and RBAC, private networking, Bicep and Azure CLI deployments</li>
<li>Deploy and manage foundation models: serverless API and managed compute, model selection, versioning and deployment strategies, provisioned throughput units</li>
<li>Implement prompt versioning and management: prompt design, prompt variants and comparison, version control for prompts with Git</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Implement Generative AI Quality Assurance and Observability (10-15%)</h3>
<ul>
<li>Configure evaluation for generative AI applications and agents: test datasets and data mapping, groundedness, relevance, coherence and fluency metrics</li>
<li>Configure risk and safety evaluations and automated evaluation workflows with built-in and custom evaluators</li>
<li>Implement observability: continuous monitoring in Foundry, latency and throughput, token and cost metrics, logging and tracing</li>
</ul>
<h3 class="course-topic-h3">Topic 5 Optimize Generative AI Systems and Model Performance (10-15%)</h3>
<ul>
<li>Optimize RAG: similarity thresholds, chunk sizes, retrieval strategies, embedding model selection and hybrid search</li>
<li>Evaluate and improve RAG with relevance metrics and A/B testing</li>
<li>Implement advanced fine-tuning: fine-tuning methods, synthetic data, monitoring fine-tuned models and promoting them to production</li>
</ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey) AND store_id <> 0;

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c1762_old;
CREATE TEMPORARY TABLE tmp_c1762_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c1762_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename those system rows in place, so the new slug resolves immediately.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 3) Legacy RP rows (MB-800 / MB-820 lives) that pointed at any old-slug path -> the new bare slug.
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Every old path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c1762_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c1762_old;

-- ---------------------------------------------------- search redirects ----
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect = CONCAT('https://www.tertiarycourses.com.sg/', @old_slug, '.html');
