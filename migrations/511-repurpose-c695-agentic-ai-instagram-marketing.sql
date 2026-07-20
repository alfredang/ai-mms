-- Repurpose course C695 from "Master Instagram Marketing Strategies to
-- Increase Followers and Drive Sales" to "Agentic AI for Instagram Marketing"
-- (name, overview, curriculum, meta, url_key, image labels, cover).
-- Price ($700) and 2-day duration (15) are intentionally kept.
-- Cover re-rendered 2026-07-18 with the new title (no funding chips —
-- funding chips come from tags, not the cover, for this course) and
-- uploaded to R2.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0, and drops url_path at every scope so the
-- Catalog URL Rewrites indexer regenerates the new URL (old URL 301s).
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C695.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C695');
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
SELECT 4, @a_name, 0, @e, 'Agentic AI for Instagram Marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Put AI agents to work on your Instagram marketing in this hands-on 2-day Agentic AI for Instagram Marketing course. Instead of manually writing captions, scheduling posts and answering every comment yourself, you will learn to build agentic AI workflows&mdash;using tools such as ChatGPT, Claude and n8n&mdash;that plan your content calendar, generate on-brand posts, captions and hashtags, and publish to Instagram on schedule. Starting from the fundamentals of AI agents and effective prompting, you will set up a complete AI-assisted content pipeline for an Instagram Business account.</p>
<p>The course then moves into automating engagement and growth: building agents that respond to comments and direct messages, capture leads, and keep your community active around the clock. You will also use AI to analyse Instagram Insights, generate performance reports, and optimise ad campaigns&mdash;audiences, budgets and creatives&mdash;through continuous feedback loops. By the end of the course, you will be able to design, build and run an agentic AI marketing system that grows your Instagram followers and drives sales while you focus on strategy.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Foundations of Agentic AI for Instagram Marketing</h3>
<ul>
<li>What Are AI Agents and Agentic Workflows</li>
<li>Overview of Agentic AI Tools for Marketing</li>
<li>Setting Up an Instagram Business Account for Automation</li>
<li>Effective Prompting for Marketing Content</li>
<li>Mapping the Customer Journey with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 AI-Powered Content Creation and Scheduling</h3>
<ul>
<li>Generating Posts, Captions and Hashtags with AI</li>
<li>Creating AI Images and Reels Ideas for Instagram</li>
<li>Building a Content Calendar Agent</li>
<li>Automated Post Scheduling and Publishing</li>
<li>Keeping a Consistent Brand Voice and Style</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Automating Engagement and Community Management</h3>
<ul>
<li>AI Agents for Comments and Direct Messages</li>
<li>Lead Capture and Follow-Up Automation</li>
<li>Personalised Responses and Escalation Rules</li>
<li>Managing Reviews and User-Generated Content with AI</li>
<li>Privacy, Copyright and Responsible AI Considerations</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Analytics, Ads and Optimisation with AI Agents</h3>
<ul>
<li>Analysing Instagram Insights with AI</li>
<li>Automated Performance Reports and Dashboards</li>
<li>AI-Assisted Instagram Ads Campaigns</li>
<li>Audience, Budget and Creative Optimisation</li>
<li>Retargeting Strategies and Continuous Improvement Loops</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Agentic AI for Instagram Marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Agentic AI, Instagram Marketing, AI Agents, AI Marketing Automation, Social Media Marketing, AI Content Creation, Instagram Ads, ChatGPT, Claude, n8n, Marketing Course, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Automate your Instagram marketing with AI agents. Build agentic AI workflows for content creation, scheduling, engagement, analytics and ads in this hands-on 2-day course at Tertiary Courses Singapore.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'agentic-ai-for-instagram-marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title, uploaded to R2 2026-07-18
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C695-20260717-174857.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Agentic AI for Instagram Marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Agentic AI for Instagram Marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Agentic AI for Instagram Marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_il, @a_sil, @a_til, @a_ciu);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Stale url_path rows point at the old social-media-marketing-with-instagram
-- URL; drop them at every scope so the Catalog URL Rewrites indexer regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;

-- Funding block: the old WSQ link 301s (the WSQ course was renamed to
-- "WSQ - Driving Brand Engagement with Proven Instagram Social Media
-- Marketing Strategies"); point directly at the live 200 URL. Full-overwrite
-- UPDATE by identifier (content-only — never a cms/block model save, which
-- would wipe the cms_block_store mapping). No-op on sites without the block.
UPDATE cms_block SET content='<h2>Funding and Grant Applications</h2>\n\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-driving-brand-engagement-with-proven-instagram-social-media-marketing-strategies.html" title="WSQ - Driving Brand Engagement with Proven Instagram Social Media Marketing Strategies">WSQ - Driving Brand Engagement with Proven Instagram Social Media Marketing Strategies</a></span></p>'
WHERE identifier='course_C695_funding_and_grant';
