-- Repurpose course C430 (entity_id 430) from "Deep Learning and Machine
-- Learning with TensorFlow" to "AI Vibe Coding for Machine Learning". Part of
-- the non-WSQ AI Vibe Coding series (2 days / 4 topics, 2 per day). Already
-- 15h / 2 days; price ($700) set in the shared price migration, funding block
-- + series badge handled elsewhere.
--
-- Scope: store_id 0 (single SG store). url_key unchanged. Idempotent.
-- No content line ends in a semicolon (apply.php splits on semicolon-at-EOL).

SET @entity_id := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C430');

SET @attr_name             := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @attr_short_description := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @attr_description       := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @attr_meta_title        := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @attr_meta_description  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @attr_meta_keyword      := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @attr_duration          := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @attr_course_image_url  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');

-- name
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_name, 0, @entity_id, 'AI Vibe Coding for Machine Learning')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- short_description / overview
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_short_description, 0, @entity_id, '<p>Build machine learning models with AI Vibe Coding for Machine Learning. This hands-on 2-day course teaches you how to use AI coding assistants such as Cursor, GitHub Copilot and Claude to write, train and evaluate machine learning models in Python. Instead of wrestling with framework syntax, you will vibe code &mdash; describing the data, model and metrics you want in plain language and letting AI generate, refactor and debug your ML code while you focus on the problem and the results.</p>
<p>Through practical projects, participants will prepare and explore datasets, train classic machine learning and deep learning models, evaluate and tune their performance, and deploy a model behind a simple app &mdash; all with an AI pair programmer at their side. You will also learn to review, test and validate AI-generated code and results so your models are sound and reproducible. By the end of the course, you will be able to build, evaluate and ship machine learning solutions faster and more confidently by combining core ML fundamentals with an effective AI vibe-coding workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- description / topics (4 topics, 2 per day)
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_description, 0, @entity_id, '<h3 class="course-topic-h3">Topic 1 Getting Started with AI Vibe Coding for Machine Learning</h3>
<ul>
<li>Introduction to Machine Learning and Vibe Coding</li>
<li>Setting Up Python, ML Libraries and AI Coding Assistants (Cursor, GitHub Copilot, Claude)</li>
<li>Loading and Exploring a Dataset from a Prompt</li>
<li>Effective Prompting for Machine Learning Code</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Building and Training Models with AI</h3>
<ul>
<li>Preparing and Cleaning Data</li>
<li>Training Classic Machine Learning Models</li>
<li>Building Neural Networks with AI Assistance</li>
<li>Explaining and Debugging Models with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Evaluating and Improving Models</h3>
<ul>
<li>Measuring Model Performance</li>
<li>Tuning Hyperparameters</li>
<li>Avoiding Overfitting and Data Leakage</li>
<li>Reviewing and Refactoring AI-Generated Code</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Deploying Machine Learning with AI</h3>
<ul>
<li>Saving and Loading Trained Models</li>
<li>Serving a Model behind a Simple App</li>
<li>Testing and Validating Predictions</li>
<li>Packaging and Sharing Your ML Project</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_title
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_title, 0, @entity_id, 'AI Vibe Coding for Machine Learning | Tertiary Courses Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_description
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_description, 0, @entity_id, 'Build machine learning models with AI vibe coding. Master data prep, model training, evaluation, tuning and deployment using AI assistants like Cursor, GitHub Copilot and Claude in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- meta_keyword
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_meta_keyword, 0, @entity_id, 'AI Vibe Coding, Machine Learning, Python, Cursor, GitHub Copilot, Claude, Model Training, Neural Networks, Model Evaluation, Deployment, AI Coding')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- duration (2 days = 15h)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_duration, 0, @entity_id, '15')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- course_image_url (new branded cover already uploaded to R2)
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @attr_course_image_url, 0, @entity_id, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C430-20260711-063358.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
