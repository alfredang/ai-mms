-- Repurpose course C539 from "Deep Learning with PyTorch" to
-- "AI Vibe Coding with PyTorch Deep Learning" (AI Vibe Coding Series,
-- 2 days / 15h / 4 topics). name, overview, topics, meta, cover image,
-- duration. Price already $700 — C539 also added to shared migration 347.
-- url_key intentionally UNCHANGED (series rule — preserves URL + SEO).
-- Badge set here directly (edited shared migration 342 would never re-run on
-- prod); funding block link fixed in 480.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C539.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C539');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_badge := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_series_badge');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI Vibe Coding with PyTorch Deep Learning' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Build real deep learning models without writing every line of PyTorch yourself. In this hands-on 2-day course you will use AI coding assistants&mdash;Cursor, GitHub Copilot and Claude&mdash;to vibe code deep learning workflows end to end: describe the model you want in plain English, let the AI generate the PyTorch code for tensors, training loops and network architectures, then review, debug and iterate with follow-up prompts. You will learn the prompting patterns that keep AI-generated deep learning code correct, trainable and reproducible.</p>
<p>Over four practical topics you will vibe code the full deep learning journey&mdash;from PyTorch tensors and autograd, to neural networks for regression and classification, to convolutional neural networks and transfer learning for image recognition, and finally recurrent networks for sequence and time series data. By the end of the course, you will have a portfolio of working PyTorch models and a repeatable AI vibe coding workflow you can apply to any deep learning problem.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 AI Vibe Coding for PyTorch Fundamentals</h3>
<ul>
<li>What Is AI Vibe Coding</li>
<li>Setting Up Cursor, GitHub Copilot and Claude for PyTorch</li>
<li>Prompting Patterns for Correct Deep Learning Code</li>
<li>Vibe Coding PyTorch Tensor Operations</li>
<li>Computation Graphs and Autograd with AI Assistance</li>
<li>Reviewing and Debugging AI-Generated PyTorch Code</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Vibe Coding Neural Networks</h3>
<ul>
<li>Neural Network Architectures, Activation and Loss Functions</li>
<li>Vibe Coding a Regression Model in PyTorch</li>
<li>Vibe Coding a Classification Model with Softmax and Cross Entropy</li>
<li>Generating Training Loops, Optimizers and Metrics from Prompts</li>
<li>Saving, Loading and Iterating on Models</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Vibe Coding Convolutional Neural Networks</h3>
<ul>
<li>Overview of CNNs: Convolution, Pooling and Padding</li>
<li>Vibe Coding a CNN Image Classifier</li>
<li>Diagnosing Overfitting with AI Assistance</li>
<li>Data Augmentation and Regularization via Prompts</li>
<li>Transfer Learning with Pre-Trained Models</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Vibe Coding Recurrent Networks for Sequence Data</h3>
<ul>
<li>Overview of RNNs, LSTM and GRU</li>
<li>Vibe Coding an LSTM for Time Series Forecasting</li>
<li>Tuning Sequence Models with Follow-Up Prompts</li>
<li>Evaluating and Visualizing Model Performance</li>
<li>Packaging a Complete Deep Learning Project</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI Vibe Coding with PyTorch Deep Learning' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Vibe code PyTorch deep learning with Cursor, GitHub Copilot and Claude in this hands-on 2-day course. Build neural networks, CNNs with transfer learning, and LSTMs for time series from plain-English prompts.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI Vibe Coding, PyTorch, Deep Learning, Neural Networks, CNN, LSTM, Transfer Learning, Cursor, GitHub Copilot, Claude, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C539-20260717-091303.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @e, '15' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_badge, 0, @e, 'AI Vibe Coding Series' FROM DUAL WHERE @e IS NOT NULL AND @a_badge IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_img, @a_dur);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
