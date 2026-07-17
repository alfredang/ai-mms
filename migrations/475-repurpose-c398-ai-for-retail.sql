-- Repurpose course C398 from "Data Visualisation with R Training" to
-- "AI for Retail" (1 day / 2 topics — generative AI and AI agents for retail
-- marketing content, customer service, personalisation, demand forecasting
-- and pricing). name, overview, topics, meta, url_key, image labels, cover.
-- Price ($350, 1 day) and duration (7.5) intentionally kept.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C398.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C398');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI for Retail' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Transform the way you run your retail business with our hands-on AI for Retail course. AI is reshaping every corner of retail&mdash;from writing product descriptions and marketing campaigns to answering customer enquiries, personalising promotions, forecasting demand and setting prices. In this practical 1-day course, you will learn what modern AI tools can do for retailers, and how to apply generative AI and AI agents to your daily retail operations&mdash;no programming background required.</p>
<p>Through guided exercises, participants will use AI assistants to generate product listings, marketing copy and visuals, set up AI-powered customer service and personalised recommendations, and apply AI to demand forecasting, inventory planning, pricing and sales analytics. You will also learn how to validate AI outputs, protect customer data and adopt AI responsibly. By the end of the course, you will be able to put AI to work across your retail operations to save time, lift sales and deliver a better customer experience.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Introduction to AI for Retail</h3>
<ul>
<li>The AI Landscape: From Generative AI to AI Agents</li>
<li>AI Use Cases Across the Retail Value Chain</li>
<li>Hands-On with AI Assistants: ChatGPT, Claude and Copilot</li>
<li>Generating Product Descriptions, Marketing Copy and Visuals with AI</li>
<li>Customer Data Privacy, Governance and Responsible AI in Retail</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Applying AI to Retail Operations and Customer Experience</h3>
<ul>
<li>AI-Powered Customer Service and Chatbots</li>
<li>Personalised Recommendations and Targeted Promotions</li>
<li>Demand Forecasting and Inventory Planning with AI</li>
<li>AI for Pricing, Merchandising and Sales Analytics</li>
<li>Building Simple AI Workflows for Day-to-Day Retail Tasks</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI for Retail' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Master AI for Retail in this hands-on 1-day course. Apply AI to marketing content, customer service, personalisation, demand forecasting and pricing at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI for Retail, Retail AI Course, Generative AI Retail, AI Agents Retail, Retail Marketing AI, AI Customer Service, Personalised Recommendations, Demand Forecasting AI, AI Pricing, Retail Automation Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'ai-for-retail' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C398-20260717-090148.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image alt labels still carried the old "R Data Visualization" title.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'AI for Retail' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'AI for Retail' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'AI for Retail' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_img, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
