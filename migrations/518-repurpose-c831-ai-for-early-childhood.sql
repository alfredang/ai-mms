-- Repurpose course C831 from "Mastering Agentic AI on No-Code Platforms" to
-- "AI for Early Childhood" (name, overview, curriculum, meta, url_key,
-- image labels, media-gallery label, cover).
-- Price ($700) and 2-day duration are intentionally kept.
-- Cover re-rendered 2026-07-18 with the new title (no funding chips) and
-- uploaded to R2.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0, and drops url_path at every scope so the
-- Catalog URL Rewrites indexer regenerates the new URL (old URL 301s).
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C831.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C831');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'AI for Early Childhood' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Bring AI into the preschool classroom in this hands-on 2-day AI for Early Childhood course, designed for preschool teachers, early childhood educators and centre leaders. Generative AI tools such as ChatGPT, Gemini and Canva AI can take hours off your weekly workload &mdash; no technical background required. You will start with the fundamentals of Generative AI and how to use it safely and responsibly in an early childhood setting, then apply it hands-on to plan lessons, design learning activities and create stories, songs, worksheets and visual aids for young learners.</p>
<p>The course then goes deeper into creative classroom content and everyday documentation: generating illustrated storybooks, songs and simple educational videos with AI, writing observations, learning stories and progress reports faster, and crafting engaging newsletters and parent updates. Throughout, you will learn to protect children''s data and use AI ethically in line with PDPA. By the end of the course, you will be able to confidently use AI to save time on planning and paperwork so you can focus on what matters most &mdash; the children.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Get Started with AI for Early Childhood</h3>
<ul>
<li>What is Generative AI and How It Works</li>
<li>AI Tools for Educators - ChatGPT, Gemini and Canva AI</li>
<li>Use Cases of AI in Early Childhood Education</li>
<li>Responsible and Safe Use of AI with Young Children</li>
<li>Write Effective Prompts for Classroom Tasks</li>
</ul>
<h3 class="course-topic-h3">Topic 2 AI for Lesson Planning and Learning Materials</h3>
<ul>
<li>Designing Lesson Plans and Learning Activities with AI</li>
<li>Creating Stories, Songs and Rhymes for Young Learners</li>
<li>Generating Worksheets, Flashcards and Visual Aids</li>
<li>Differentiating Activities for Diverse Learners</li>
</ul>
<h3 class="course-topic-h3">Topic 3 AI for Creative Classroom Content</h3>
<ul>
<li>Generating Images and Illustrated Storybooks with AI</li>
<li>Creating Songs and Audio for Music and Movement</li>
<li>Making Simple Educational Videos with AI</li>
<li>Designing Classroom Displays and Craft Ideas</li>
</ul>
<h3 class="course-topic-h3">Topic 4 AI for Documentation and Parent Communication</h3>
<ul>
<li>Writing Observations and Learning Stories with AI</li>
<li>Drafting Progress Reports and Portfolios</li>
<li>Creating Newsletters and Parent Updates</li>
<li>Data Privacy, PDPA and Ethical Use of Child Data</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'AI for Early Childhood' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'AI for Early Childhood, AI for Preschool Teachers, Early Childhood Education, Generative AI for Educators, ChatGPT for Teachers, AI Lesson Planning, Learning Stories, Parent Communication, AI Course Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Empower early childhood educators with AI. Learn to plan lessons, create learning materials, write learning stories and engage parents with Generative AI in this hands-on 2-day course at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'ai-for-early-childhood' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-18
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C831-20260717-180754.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'AI for Early Childhood' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'AI for Early Childhood' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'AI for Early Childhood' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Product-page zoom gallery renders the per-image label as img title/alt
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'AI for Early Childhood'
WHERE g.entity_id = @e AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_il, @a_sil, @a_til, @a_ciu);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Stale url_path rows point at the old mastering-agentic-ai-on-no-code-platforms
-- URL; drop them at every scope so Catalog URL Rewrites regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;

-- Re-categorise: the course leaves the agentic-AI domain, so drop it from the
-- Agentic AI Series / AI Agents Series and add it to the AI Applications
-- Series. Categories resolved BY NAME (ids differ per partner site).
DELETE cp FROM catalog_category_product cp
JOIN catalog_category_entity_varchar v ON v.entity_id = cp.category_id AND v.store_id = 0
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
WHERE cp.product_id = @e AND @e IS NOT NULL AND v.value IN ('Agentic AI Series', 'AI Agents Series');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0
FROM catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'name' AND a.entity_type_id = 3
WHERE v.store_id = 0 AND v.value = 'AI Applications Series' AND @e IS NOT NULL;

-- Funding block: point at the live funded equivalent (WSQ - Create Engaging
-- Content with Generative AI (GenAI), direct 200 URL verified 2026-07-18).
-- Content-only UPDATE by identifier - never a cms/block model save, which
-- would wipe the cms_block_store mapping. No-op on sites without the block.
UPDATE cms_block SET content='<h2>Funding and Grant Applications</h2>\n\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-create-engaging-content-with-generative-ai-genai.html" title="WSQ - Create Engaging Content with Generative AI (GenAI)">WSQ - Create Engaging Content with Generative AI (GenAI)</a></span></p>'
WHERE identifier='course_C831_funding_and_grant';
