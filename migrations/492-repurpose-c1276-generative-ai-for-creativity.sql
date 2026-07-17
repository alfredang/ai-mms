-- Repurpose course C1276 from "Boosting Your Productivity and Creativity
-- with Generative AI (GenAI)" to "Generative AI for Creativity"
-- (1 day / 3 topics — GenAI creative tools, creative content generation,
-- and AI-assisted ideation workflows).
-- name, overview, topics, meta, url_key, image labels.
-- Price ($350, 1 day) and duration (7.5h) intentionally kept.
-- Cover image intentionally kept (regenerate via the cover dialog later).
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C1276.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C1276');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Generative AI for Creativity' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Unlock your creative potential with the power of Generative AI. In this hands-on 1-day Generative AI for Creativity course, you will learn how to use AI assistants such as ChatGPT, Claude, Gemini and Copilot&mdash;together with AI image tools&mdash;to brainstorm fresh ideas, create compelling written and visual content, and push past creative blocks in a fraction of the time it takes to work manually. No prior AI experience is required.</p>
<p>Through guided exercises, participants will master the prompting techniques that turn Generative AI into a true creative partner&mdash;generating ideas and mind maps, drafting stories, scripts and marketing copy, creating images and visual concepts, and refining rough drafts into polished creative work. By the end of the course, you will have a repeatable AI-assisted creative workflow you can apply immediately to your own projects at work or in your creative practice.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Generative AI for Creative Work</h3>
<ul>
<li>Overview of Generative AI Tools: ChatGPT, Claude, Gemini and Copilot</li>
<li>How Generative AI Supports the Creative Process</li>
<li>Prompt Engineering Essentials for Creative Output</li>
<li>Setting Tone, Style and Voice in AI-Generated Content</li>
<li>Copyright, Originality and Responsible Use of AI-Generated Work</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Creating Written and Visual Content with AI</h3>
<ul>
<li>Drafting Stories, Scripts and Marketing Copy with AI</li>
<li>Rewriting, Polishing and Adapting Content for Different Audiences</li>
<li>Generating Images and Visual Concepts with AI Image Tools</li>
<li>Creating Social Media Content and Presentation Visuals with AI</li>
<li>Iterating on Creative Drafts with Follow-Up Prompts</li>
</ul>
<h3 class="course-topic-h3">Topic 3 AI-Assisted Ideation and Creative Workflows</h3>
<ul>
<li>Brainstorming Ideas and Building Mind Maps with AI</li>
<li>Using AI to Challenge Conventional Thinking and Explore Alternatives</li>
<li>Overcoming Creative Blocks with AI Prompting Techniques</li>
<li>Combining Multiple AI Tools into a Creative Workflow</li>
<li>Presenting and Pitching Creative Ideas with AI Support</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Generative AI for Creativity' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Learn Generative AI for Creativity in this hands-on 1-day course. Use ChatGPT, Claude, Gemini and AI image tools to brainstorm ideas and create content at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Generative AI, Creativity, AI Content Creation, ChatGPT, Claude, Gemini, Copilot, AI Image Generation, Brainstorming with AI, Prompt Engineering, Creative Workflow, Tertiary Courses, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'generative-ai-for-creativity' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Generative AI for Creativity' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Generative AI for Creativity' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Generative AI for Creativity' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);
