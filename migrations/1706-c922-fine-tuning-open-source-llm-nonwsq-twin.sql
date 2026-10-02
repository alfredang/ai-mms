-- C922 Fine Tuning Open Source LLM = the 1-day non-WSQ twin of TGS-2025059025 (WSQ - Generative AI Model
-- Development and Fine Tuning, 4 days). Courseware v1.0 converted from the WSQ v3.0 set — all 4 Learning Units and
-- 15 topics compressed into one day, 6 labs in class + 20 self-paced
-- (github.com/tertiarycourses/C922-Fine-Tuning-Open-Source-LLM). Follows 1230 (which repurposed the entity from
-- "Deploy Jenkins with AI" with C922's own copy).
--
-- 1. "What's This Course About" copied from the parent (its "This course, <parent title>," opener names this course).
--    No day count, no WSQ wording. ASCII/entity literal (not a parent JOIN — see 1619).
-- 2. Course topics = the parent's syllabus as taught in the v3.0 courseware: 4 LUs / 15 topics, K/A codes dropped.
--    (The parent's own storefront LSN_DATA lists only LU1-LU3 with pre-v3.0 titles, so it is not copied verbatim.)
-- 3. Prerequisite software/hardware: was Docker (left over from the Jenkins course) -> Colab + Hugging Face.
-- 4. Job roles (whoshouldattend): were DevOps roles from the Jenkins course -> the parent's ML/AI roles.
-- 5. meta_keyword: was Jenkins / CI/CD / Docker -> fine-tuning keywords.
-- Store-scope overrides of these attributes are removed so store 0 renders.
-- Name / slug / fee ($350) / duration 7.5 / sessions 1 / meta_description / funding block already correct (1230).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: catalog_product_flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C922' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025059025' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, @pid, '<p>In the era of advanced artificial intelligence, the ability to develop and fine-tune Generative AI (GenAI) models is critical for building high-performance, domain-specific solutions. This course, Fine Tuning Open Source LLM, equips learners with the practical skills and technical knowledge to design, optimize, and evaluate modern AI models using cloud-based tools and frameworks.</p> <p>Learners will begin by exploring techniques for data ingestion and transformation, including the use of synthetic data to enhance model performance and address data limitations. The course then focuses on building efficient data pipelines and feature engineering workflows, applying optimization strategies to improve model training and scalability.</p> <p>Participants will gain hands-on experience in fine-tuning pre-trained multi-modal models, leveraging advanced training approaches, loss functions, and parameter optimization techniques to adapt models for specific use cases. Emphasis is placed on improving model accuracy, efficiency, and robustness in real-world deployment scenarios.</p> <p>In addition, the course addresses critical considerations in modern AI development, including bias detection, explainability, and alignment with performance benchmarks. Learners will evaluate AI solutions to ensure they are reliable, ethical, and aligned with organizational and regulatory expectations.</p> <p>By the end of the course, learners will be able to design end-to-end GenAI workflows&mdash;from data preparation to model fine-tuning and evaluation&mdash;enabling them to develop scalable, responsible, and high-performing AI solutions for a wide range of applications.</p> <p>This course is suitable for data professionals, AI practitioners, and developers seeking to deepen their expertise in Generative AI model development, optimization, and fine-tuning techniques.</p>'
  FROM eav_attribute a WHERE @ok AND a.entity_type_id = 4 AND a.attribute_code = 'short_description'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, @pid, '<!-- LSN_DATA: [{"title":"LU1: Data Engineering","subsecs":["Topic 1: Create data repositories for fine tuning","Topic 2: Identify and implement a dataset ingestion solution","Topic 3: Identify and implement a data transformation solution"],"links":[]},{"title":"LU2: Exploratory Data Analysis","subsecs":["Topic 1: Sanitize and prepare data for modelling","Topic 2: Perform feature engineering for fine tuning","Topic 3: Analyze and visualize data for fine tuning insights"],"links":[]},{"title":"LU3: Modelling","subsecs":["Topic 1: Frame business problems as fine-tuning problems","Topic 2: Select the appropriate model and adaptation method","Topic 3: Train and fine-tune models with LoRA, QLoRA and Unsloth","Topic 4: Perform hyperparameter optimization","Topic 5: Evaluate fine-tuned models"],"links":[]},{"title":"LU4: Machine Learning Implementation and Operations","subsecs":["Topic 1: Build and benchmark generative solutions against state of the art","Topic 2: Recommend and implement bias mitigation and fairness interventions","Topic 3: Apply interpretability and explainability methods","Topic 4: Deploy and operationalize fine-tuned models"],"links":[]}] -->\n<p><strong>LU1: Data Engineering</strong></p>\n<p><em>Topic 1: Create data repositories for fine tuning</em></p>\n<p><em>Topic 2: Identify and implement a dataset ingestion solution</em></p>\n<p><em>Topic 3: Identify and implement a data transformation solution</em></p>\n<p><strong>LU2: Exploratory Data Analysis</strong></p>\n<p><em>Topic 1: Sanitize and prepare data for modelling</em></p>\n<p><em>Topic 2: Perform feature engineering for fine tuning</em></p>\n<p><em>Topic 3: Analyze and visualize data for fine tuning insights</em></p>\n<p><strong>LU3: Modelling</strong></p>\n<p><em>Topic 1: Frame business problems as fine-tuning problems</em></p>\n<p><em>Topic 2: Select the appropriate model and adaptation method</em></p>\n<p><em>Topic 3: Train and fine-tune models with LoRA, QLoRA and Unsloth</em></p>\n<p><em>Topic 4: Perform hyperparameter optimization</em></p>\n<p><em>Topic 5: Evaluate fine-tuned models</em></p>\n<p><strong>LU4: Machine Learning Implementation and Operations</strong></p>\n<p><em>Topic 1: Build and benchmark generative solutions against state of the art</em></p>\n<p><em>Topic 2: Recommend and implement bias mitigation and fairness interventions</em></p>\n<p><em>Topic 3: Apply interpretability and explainability methods</em></p>\n<p><em>Topic 4: Deploy and operationalize fine-tuned models</em></p>\n'
  FROM eav_attribute a WHERE @ok AND a.entity_type_id = 4 AND a.attribute_code = 'description'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, @pid, '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n<li>Basic Python programming is recommended</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<p>Target Age Group: 18-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<ul>\n<li>A Google account for Google Colab (free T4 GPU runtime) - no local installation needed</li>\n<li>A free Hugging Face account</li>\n</ul>\n<p><strong>Hardware:</strong>&nbsp;Windows or Mac laptop with a modern web browser. No local GPU is required.</p>'
  FROM eav_attribute a WHERE @ok AND a.entity_type_id = 4 AND a.attribute_code = 'prerequisite'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, @pid, '<ul>\n<li>Machine Learning Engineer</li>\n<li>Data Scientist</li>\n<li>AI Engineer</li>\n<li>Data Engineer</li>\n<li>Cloud Machine Learning Architect</li>\n<li>ML Operations Engineer</li>\n<li>AI/ML Consultant</li>\n<li>Applied Scientist</li>\n<li>Deep Learning Engineer</li>\n<li>Cloud Solutions Architect</li>\n<li>Data Analyst</li>\n<li>DevOps Engineer (ML-focused)</li>\n<li>Technical Product Manager (AI/ML)</li>\n<li>AI Research Engineer</li>\n<li>Software Engineer (ML Integration)</li>\n<li>Automation Engineer (AI/ML)</li>\n</ul>'
  FROM eav_attribute a WHERE @ok AND a.entity_type_id = 4 AND a.attribute_code = 'whoshouldattend'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, @pid, 'fine tuning LLM, open source LLM, LoRA, QLoRA, Unsloth, PEFT, Hugging Face, Llama fine tuning, Google Colab, generative AI model development, AI course Singapore'
  FROM eav_attribute a WHERE @ok AND a.entity_type_id = 4 AND a.attribute_code = 'meta_keyword'
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE t FROM catalog_product_entity_text t
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('short_description', 'description', 'prerequisite', 'whoshouldattend', 'meta_keyword')
 WHERE @ok AND t.entity_id = @pid AND t.store_id <> 0;
