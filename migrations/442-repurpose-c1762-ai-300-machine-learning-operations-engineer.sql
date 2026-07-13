-- Repurpose course C1762 from "MB-820 Microsoft Certified Dynamics 365 Business
-- Central Developer" to "AI-300 Microsoft Certified Machine Learning Operations
-- Engineer Associate". Microsoft certification exam-prep course. name, url_key,
-- overview (short_description), exam domains (description) with official
-- skills-measured weightings, meta (title/description/keyword). Price and
-- duration unchanged. Cover regenerated separately via CourseImage dialog.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1762');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'AI-300 Microsoft Certified Machine Learning Operations Engineer Associate') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>The AI-300 Microsoft Certified Machine Learning Operations Engineer Associate course equips learners with the knowledge and skills required to set up and operate machine learning operations (MLOps) and generative AI operations (GenAIOps) on Azure. Participants will explore designing MLOps infrastructure with Azure Machine Learning, managing the model lifecycle, and building GenAIOps infrastructure with Microsoft Foundry, GitHub Actions and infrastructure as code.</p>
<p>Learners will gain hands-on expertise training, registering, deploying and monitoring machine learning models, deploying foundation models, and implementing prompt versioning, evaluation, observability and cost optimization for generative AI applications and agents. Additionally, the course covers optimizing retrieval-augmented generation and advanced fine-tuning. By completing this course, participants will be prepared to deliver scalable, automated and well-monitored AI solutions on Azure.</p>
<h2>Microsoft Learning Partner</h2>
<p>We are <strong>Authorised&nbsp;Microsoft Learning Partner (Org ID:&nbsp; 5238476).</strong> To get the official Microsoft certification, please register your certification exam at Pearson Vue Test Center.</p>
<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<p>This course prepares you for the <strong>AI-300</strong> certification exam, covering all official skills measured and their approximate weightings:</p>
<h3 class="course-topic-h3">Domain 1 Design and implement an MLOps infrastructure (15-20%)</h3>
<ul>
<li>Create and manage a Machine Learning workspace, datastores and compute targets, and configure identity and access management</li>
<li>Create and manage data assets, environments and components, and share assets across workspaces using registries</li>
<li>Configure GitHub integration, and deploy Machine Learning workspaces and resources using Bicep and Azure CLI</li>
<li>Automate resource provisioning with GitHub Actions workflows and restrict network access to workspaces</li>
<li>Manage source control for machine learning projects using Git</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Implement machine learning model lifecycle and operations (25-30%)</h3>
<ul>
<li>Orchestrate model training: configure experiment tracking with MLflow, use automated machine learning and notebooks, and automate hyperparameter tuning</li>
<li>Run training scripts, manage distributed training, implement training pipelines, and compare model performance across jobs</li>
<li>Register and version models, package feature retrieval specifications, and evaluate models using responsible AI principles</li>
<li>Deploy models as real-time or batch endpoints, test and troubleshoot endpoints, and implement progressive rollout and safe rollback</li>
<li>Monitor production models: detect data drift, track performance metrics, and configure retraining or alert triggers</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Design and implement a GenAIOps infrastructure (20-25%)</h3>
<ul>
<li>Create and configure Foundry resources and project environments, and configure identity and access management with managed identities and RBAC</li>
<li>Implement network security and private networking, and deploy infrastructure using Bicep templates and Azure CLI</li>
<li>Deploy foundation models with serverless API endpoints and managed compute, and select appropriate models for use cases</li>
<li>Implement model versioning and production deployment strategies, and configure provisioned throughput units for high-volume workloads</li>
<li>Design and develop prompts, create prompt variants, and implement version control for prompts using Git repositories</li>
</ul>
<h3 class="course-topic-h3">Domain 4 Implement generative AI quality assurance and observability (10-15%)</h3>
<ul>
<li>Create test datasets and data mapping, and implement AI quality metrics including groundedness, relevance, coherence and fluency</li>
<li>Configure risk and safety evaluations for harmful content detection, and set up automated evaluation workflows</li>
<li>Monitor performance metrics including latency, throughput and response times using continuous monitoring in Foundry</li>
<li>Track and optimize cost metrics including token consumption and resource usage</li>
<li>Configure detailed logging, tracing and debugging for production troubleshooting</li>
</ul>
<h3 class="course-topic-h3">Domain 5 Optimize generative AI systems and model performance (10-15%)</h3>
<ul>
<li>Optimize retrieval-augmented generation (RAG) by tuning similarity thresholds, chunk sizes and retrieval strategies</li>
<li>Select and fine-tune embedding models for domain-specific accuracy, and implement hybrid semantic and keyword search</li>
<li>Evaluate and improve RAG performance using relevance metrics and A/B testing</li>
<li>Design and implement advanced fine-tuning methods, and create and manage synthetic data for fine-tuning</li>
<li>Monitor and optimize fine-tuned models from development through production deployment</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI-300 Microsoft Certified Machine Learning Operations Engineer Associate') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for Microsoft Exam AI-300 and become a Certified Machine Learning Operations Engineer Associate. Master MLOps and GenAIOps on Azure with Azure Machine Learning and Microsoft Foundry at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI-300 course Singapore, Machine Learning Operations Engineer, MLOps, GenAIOps, Microsoft AI certification, Azure Machine Learning, Microsoft Foundry, MLflow, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-300-microsoft-certified-machine-learning-operations-engineer-associate') ON DUPLICATE KEY UPDATE value = VALUES(value);
