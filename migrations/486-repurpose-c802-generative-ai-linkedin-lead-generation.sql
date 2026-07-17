-- Repurpose course C802 from "Linkedin for Lead Generation"
-- to "Generative AI for LinkedIn Lead Generation" (1 day / 2 topics —
-- AI-assisted profile + content creation, and AI-powered outreach).
-- name, overview, topics, meta, url_key, cover, image labels.
-- Price ($350, 1 day) and duration intentionally kept.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C802.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C802');
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
SELECT 4, @a_name, 0, @e, 'Generative AI for LinkedIn Lead Generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Supercharge your LinkedIn lead generation with the power of Generative AI. In this hands-on 1-day Generative AI for LinkedIn Lead Generation course, you will learn how to use AI assistants such as ChatGPT, Claude and Copilot to optimise your LinkedIn profile, craft compelling posts and articles, and position yourself as a thought leader in your industry&mdash;in a fraction of the time it takes to do it manually. No prior AI experience is required.</p>
<p>Beyond content creation, you will discover how Generative AI transforms prospecting and outreach on LinkedIn. Through guided exercises, participants will use AI to research target prospects, write personalised connection requests and follow-up messages that get responses, and build repeatable lead-nurturing workflows that convert connections into qualified business leads. By the end of the course, you will have a practical AI-powered LinkedIn lead generation system you can apply immediately to grow your pipeline.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1: Generative AI for LinkedIn Profile and Content</h3>
<ul>
<li>Overview of Generative AI Tools: ChatGPT, Claude and Copilot</li>
<li>Prompt Engineering Essentials for Marketing Copy</li>
<li>Optimise Your LinkedIn Profile and Company Page with AI</li>
<li>Create Engaging LinkedIn Posts, Articles and Carousels with AI</li>
<li>Build a Content Calendar and Thought Leadership Brand with AI</li>
<li>Data Privacy, Copyright and Responsible AI Use on LinkedIn</li>
</ul>
<h3 class="course-topic-h3">Topic 2: AI-Powered Lead Generation and Outreach</h3>
<ul>
<li>Identify and Research Target Prospects with AI</li>
<li>Craft Personalised Connection Requests and InMail Messages with AI</li>
<li>Design AI-Assisted Follow-Up and Lead Nurturing Sequences</li>
<li>Qualify Leads and Handle Objections with AI Assistants</li>
<li>Measure and Optimise Your LinkedIn Lead Generation Funnel</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Generative AI for LinkedIn Lead Generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Learn Generative AI for LinkedIn Lead Generation in this hands-on 1-day course. Use ChatGPT, Claude and Copilot to create content and win leads at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Generative AI, LinkedIn Lead Generation, ChatGPT, Claude, Copilot, AI Content Creation, LinkedIn Marketing, AI Prospecting, Personalised Outreach, B2B Marketing, Social Selling, Tertiary Courses, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'generative-ai-for-linkedin-lead-generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C802-20260717-095201.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image alt labels still carried the old "LinkedIn for Lead Generation" title
-- (store 1 even carried a stray Facebook Advertising label).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Generative AI for LinkedIn Lead Generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Generative AI for LinkedIn Lead Generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Generative AI for LinkedIn Lead Generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_img, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
