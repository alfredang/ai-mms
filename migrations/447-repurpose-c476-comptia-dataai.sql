-- Repurpose course C476 from "MD-102 Microsoft Certified Endpoint Administrator
-- Associate Training" to "CompTIA DataAI Training". CompTIA certification
-- exam-prep course (NOT Microsoft). name, url_key, overview, exam domains with
-- official weightings, meta. Also moves it out of the Microsoft certification
-- categories into "CompTIA Certification Exam Prep" (categories resolved by NAME
-- so it is partner-safe; ids differ per site). Price/duration unchanged.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C476');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'CompTIA DataAI Training') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>CompTIA DataAI (formerly DataX) is an expert-level certification that validates the advanced data science and artificial intelligence skills needed to build, deploy and operate real-world data and AI solutions. It is designed for highly experienced professionals with around five or more years in data science or a similar role, covering the full workflow from mathematics and statistics through modeling, machine learning, deep learning and machine learning operations (MLOps).</p>
<p>This course prepares experienced practitioners for the CompTIA DataAI exam, strengthening skills in exploratory data analysis, statistical methods, model development and evaluation, machine learning and deep learning implementation, data science operations and processes, and specialized applications such as natural language processing and computer vision. To get certified, register for your CompTIA DataAI exam at a Pearson VUE test center.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<p>This course prepares you for the <strong>CompTIA DataAI</strong> certification exam, covering all official exam domains and their weightings:</p>
<h3 class="course-topic-h3">Domain 1 Mathematics and statistics (17%)</h3>
<ul>
<li>Apply probability, descriptive and inferential statistics to data problems</li>
<li>Perform hypothesis testing, experimental design and significance analysis</li>
<li>Use linear algebra and calculus concepts that underpin data science and machine learning</li>
</ul>
<h3 class="course-topic-h3">Domain 2 Modeling, analysis, and outcomes (24%)</h3>
<ul>
<li>Perform exploratory data analysis, data cleaning, and feature engineering and selection</li>
<li>Build, tune and validate models, and interpret and communicate outcomes to stakeholders</li>
<li>Evaluate model performance and select appropriate metrics for the business problem</li>
</ul>
<h3 class="course-topic-h3">Domain 3 Machine learning (24%)</h3>
<ul>
<li>Implement supervised, unsupervised and ensemble machine learning techniques</li>
<li>Apply deep learning and neural network concepts</li>
<li>Address overfitting, bias, regularization and model generalization</li>
</ul>
<h3 class="course-topic-h3">Domain 4 Operations and processes (22%)</h3>
<ul>
<li>Apply the data science lifecycle and MLOps practices for deployment and monitoring</li>
<li>Manage data pipelines, versioning, reproducibility and model retraining</li>
<li>Address governance, security, ethics and responsible AI in data science operations</li>
</ul>
<h3 class="course-topic-h3">Domain 5 Specialized applications of data science (13%)</h3>
<ul>
<li>Apply natural language processing and text analytics</li>
<li>Apply computer vision and image analysis techniques</li>
<li>Apply data science to specialized and industry-specific use cases</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'CompTIA DataAI Training') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Prepare for the CompTIA DataAI (formerly DataX) certification with expert-level data science and AI training covering statistics, modeling, machine learning, MLOps and specialized applications at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'CompTIA DataAI, CompTIA DataX, data science certification, machine learning, deep learning, MLOps, statistics, NLP, computer vision, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'comptia-dataai-training') ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE cp FROM catalog_category_product cp
JOIN catalog_category_entity_varchar v ON v.entity_id=cp.category_id AND v.store_id=0
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE cp.product_id=@e AND v.value IN ('Microsoft Certification Exam Prep', 'Microsoft 365 Certification');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0 FROM catalog_category_entity_varchar v
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE v.store_id=0 AND v.value IN ('CompTIA Certification Exam Prep', 'AI Applications Series') AND @e IS NOT NULL;
