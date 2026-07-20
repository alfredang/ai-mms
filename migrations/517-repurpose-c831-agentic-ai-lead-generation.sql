-- Repurpose course C831 from "Mastering Agentic AI on No-Code Platforms" to
-- "Agentic AI for Lead Generation" (name, overview, curriculum, meta, url_key,
-- image labels, media-gallery label, cover).
-- Price ($700) and 2-day duration (15h) are intentionally kept.
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
SELECT 4, @a_name, 0, @e, 'Agentic AI for Lead Generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Turn lead generation into an always-on, autonomous engine in this hands-on 2-day Agentic AI for Lead Generation course. AI agents built on no-code platforms such as n8n can prospect, capture, qualify and score leads around the clock &mdash; without a single line of code. You will start with the fundamentals of AI agents and the lead generation funnel, then build your first lead generation agent and connect it to real capture channels such as web forms, landing pages and AI chatbots.</p>
<p>The course then goes deeper into the full lead pipeline: enriching leads with company and contact data, running deep research agents for account intelligence, and automating personalised outreach across email, LinkedIn and WhatsApp. You will build qualification and scoring agents that route hot leads straight to your CRM, design automated nurture sequences, and track the performance of your AI-powered lead engine. By the end of the course, you will be able to deploy a team of AI agents that fills your sales pipeline on autopilot.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Get Started with Agentic AI for Lead Generation</h3>
<ul>
<li>What is Agentic AI and AI Agents</li>
<li>The Lead Generation Funnel - Capture, Qualify, Nurture, Convert</li>
<li>Use Cases of AI Agents in Lead Generation</li>
<li>Introduction to Agentic AI Platforms - n8n</li>
<li>Create Your First Lead Generation Agent</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Build Lead Capture and Qualification Agents</h3>
<ul>
<li>Capturing Leads from Web Forms and Landing Pages</li>
<li>Build an AI Chatbot Lead Capture Agent</li>
<li>Lead Qualification and Scoring with AI Agents</li>
<li>Routing Qualified Leads to Your CRM</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Automate Lead Research and Enrichment</h3>
<ul>
<li>Prospecting and Lead List Building with AI Agents</li>
<li>Enriching Leads with Company and Contact Data</li>
<li>Deep Research Agents for Account Intelligence</li>
<li>Verifying and Cleaning Lead Data Automatically</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Automate Lead Nurturing and Outreach</h3>
<ul>
<li>Personalised Email Outreach with AI Agents</li>
<li>Multi-Channel Follow Up - Email, LinkedIn and WhatsApp</li>
<li>Building Automated Nurture Sequences</li>
<li>Tracking, Analytics and Optimising Your Lead Engine</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Agentic AI for Lead Generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Agentic AI for Lead Generation, AI Lead Generation, AI Agents, Lead Generation Course, n8n, No Code AI, Lead Qualification, Lead Enrichment, AI Outreach Automation, Sales Automation, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Automate lead generation with AI agents. Build no-code agentic workflows that capture, qualify, enrich and nurture leads in this hands-on 2-day course at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'agentic-ai-for-lead-generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-18
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C831-20260717-180404.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Agentic AI for Lead Generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Agentic AI for Lead Generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Agentic AI for Lead Generation' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Product-page zoom gallery renders the per-image label as img title/alt
UPDATE catalog_product_entity_media_gallery_value gv
JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
SET gv.label = 'Agentic AI for Lead Generation'
WHERE g.entity_id = @e AND @e IS NOT NULL;

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_il, @a_sil, @a_til, @a_ciu);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Stale url_path rows point at the old mastering-agentic-ai-on-no-code-platforms
-- URL; drop them at every scope so Catalog URL Rewrites regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;

-- Funding block: point at the live funded equivalent (WSQ - Formulate Digital
-- Marketing Strategy with AI Agent and Deep Research, direct 200 URL, verified
-- 2026-07-18). Content-only UPDATE by identifier - never a cms/block model
-- save, which would wipe the cms_block_store mapping. No-op on sites without
-- the block.
UPDATE cms_block SET content='<h2>Funding and Grant Applications</h2>\n\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-formulate-digital-marketing-strategy-with-ai-agent-and-deep-research.html" title="WSQ - Formulate Digital Marketing Strategy with AI Agent and Deep Research">WSQ - Formulate Digital Marketing Strategy with AI Agent and Deep Research</a></span></p>'
WHERE identifier='course_C831_funding_and_grant';
