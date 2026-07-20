-- Repurpose course C978 from "Build LLM Powered ChatBot without Coding"
-- to "Build a RAG Chatbot with n8n" (1 day / 2 topics — understanding RAG
-- chatbots and building a RAG chatbot with n8n).
-- name, overview, topics, meta, url_key, cover, image labels.
-- Price ($350, 1 day) intentionally kept.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C978.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C978');
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
SELECT 4, @a_name, 0, @e, 'Build a RAG Chatbot with n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Generic chatbots can only answer from what the AI model already knows&mdash;they fall short the moment you ask about your company&rsquo;s products, policies or documents. Retrieval-Augmented Generation (RAG) fixes this by letting a chatbot search your own knowledge base and ground every answer in your actual content. In this practical 1-day Build a RAG Chatbot with n8n course, you will learn how RAG works&mdash;embeddings, vector stores and retrieval&mdash;and build your own RAG chatbot using n8n, the popular visual workflow automation platform, with no programming background required.</p>
<p>Through guided hands-on exercises, participants will build a complete RAG chatbot in n8n&mdash;ingesting their own documents into a vector store, wiring up an AI agent with chat memory, and tuning retrieval so the bot answers accurately from their knowledge base. You will test and refine your chatbot, then deploy it as a shareable chat interface or embed it on a website. By the end of the course, you will be able to build and deploy RAG chatbots that answer questions grounded on your organisation&rsquo;s own knowledge.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Understanding RAG Chatbots</h3>
<ul>
<li>What is Retrieval-Augmented Generation (RAG) and Why Chatbots Need It</li>
<li>How RAG Works: Embeddings, Vector Stores and Retrieval</li>
<li>RAG Chatbot Use Cases: Customer Support, Internal Knowledge and FAQs</li>
<li>Introduction to n8n: Workflows, Nodes and AI Agent Components</li>
<li>Designing a RAG Chatbot: Knowledge Sources, Chunking and Prompts</li>
</ul>
<h3 class="course-topic-h3">Topic 2: Building a RAG Chatbot with n8n</h3>
<ul>
<li>Setting Up an n8n Chatbot Workflow with Chat Trigger and AI Agent</li>
<li>Ingesting Your Documents into a Vector Store</li>
<li>Connecting the AI Agent to Your Knowledge Base with Chat Memory</li>
<li>Testing and Improving Answer Accuracy of Your RAG Chatbot</li>
<li>Deploying and Embedding Your RAG Chatbot on a Website</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Build a RAG Chatbot with n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Learn to build a RAG chatbot with n8n in this hands-on 1-day course. Ground AI chatbots on your own documents with vector stores at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'RAG Chatbot Course, Build RAG Chatbot, n8n Training, n8n Chatbot, Retrieval Augmented Generation, Vector Store, AI Chatbot Course, No Code Chatbot, Knowledge Base Chatbot, AI Workflow Automation, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'build-rag-chatbot-with-n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C978-20260717-095944.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image alt labels still carried the old "Build LLM Powered ChatBot" title.
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Build a RAG Chatbot with n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Build a RAG Chatbot with n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Build a RAG Chatbot with n8n' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_img, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
