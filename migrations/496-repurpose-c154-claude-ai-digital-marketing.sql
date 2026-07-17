-- Repurpose course C154 from "Google Cloud Certified Cloud Digital Leader
-- Training" to "Claude AI for Digital Marketing" (2 days / 15h / 4 topics —
-- agentic AI workflows for website tasks, lead management, social media and
-- business process automation). name, overview, topics, meta, url_key,
-- image labels. Price ($700) and duration (15h) intentionally kept.
-- The old "Register for Google Cloud Certification" section is dropped from
-- short_description; Certificate + Funding render from the generic
-- course_C154_* cms_blocks which stay valid.
-- Cover image intentionally kept (regenerate via the cover dialog later).
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0, and drops url_path at every scope so the
-- Catalog URL Rewrites indexer regenerates the new URL.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C154.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C154');
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
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Claude AI for Digital Marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Put Claude AI to work across your entire digital marketing operation in this hands-on 2-day course. Claude is Anthropic&rsquo;s AI assistant that goes beyond chat&mdash;with agentic workflows it can update your website, create and adapt marketing content, run SEO checks, and handle routine development tasks on its own while you review and guide the work. You will learn to set up Claude for marketing, then delegate real day-to-day tasks: tracking and consolidating leads from every enquiry channel, drafting follow-ups, and generating regular performance reports automatically.</p>
<p>The course then moves into agentic social media workflows&mdash;turning one campaign idea into platform-ready captions, posts and scripts, building content calendars with approval flows, tracking performance, and monitoring comments, sentiment and content trends. Finally, you will design your own custom workflows and agents that automate the repetitive processes unique to your business. By the end of the course, you will have a working set of Claude-powered marketing automations and a practical blueprint for scaling productivity and operational efficiency across your team.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Claude AI Agents for Website and Development Tasks</h3>
<ul>
<li>Introduction to Claude AI and Agentic Workflows for Marketing</li>
<li>Setting Up Claude: Projects, Connectors and Tools</li>
<li>Automating Website Updates with AI Agents</li>
<li>AI-Assisted Marketing Content Creation</li>
<li>Running SEO Checks and Fixes with Claude</li>
<li>Automating Routine Development Tasks</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Lead Management Automation</h3>
<ul>
<li>Automating Daily Lead Tracking with Claude</li>
<li>Consolidating Enquiries Across Channels</li>
<li>Qualifying and Prioritising Leads with AI</li>
<li>Drafting Personalised Follow-Up Responses</li>
<li>Generating Regular Lead and Performance Reports</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Agentic Social Media Workflows</h3>
<ul>
<li>Generating and Adapting Content Per Platform</li>
<li>Turning One Campaign Idea into Captions, Posts and Scripts</li>
<li>Building Content Calendars with Approval Flows</li>
<li>Tracking Social Media Performance</li>
<li>Monitoring Comments and Sentiment</li>
<li>Surfacing Content Trends and Insights</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Business Process Automation with Claude</h3>
<ul>
<li>Designing Custom Workflows and Agents for Your Business</li>
<li>Automating Repetitive Marketing Operations Tasks</li>
<li>Connecting Claude to Your Business Tools</li>
<li>Human-in-the-Loop Review and Guardrails</li>
<li>Measuring Productivity and Operational Efficiency Gains</li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Claude AI for Digital Marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Automate digital marketing with Claude AI in this hands-on 2-day course. Build agentic workflows for website tasks, lead management, social media and business process automation.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Claude AI, Digital Marketing, Agentic AI, AI Agents, Marketing Automation, Lead Management, Social Media Automation, Content Creation, SEO Automation, Business Process Automation, Anthropic Claude, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'claude-ai-for-digital-marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Image alt labels (store 1 still carried stale per-store copies).
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Claude AI for Digital Marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Claude AI for Digital Marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Claude AI for Digital Marketing' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url, @a_il, @a_sil, @a_til);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Stale url_path rows point at the old google-cloud-digital-leader URL; drop
-- them at every scope so the Catalog URL Rewrites indexer regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;
