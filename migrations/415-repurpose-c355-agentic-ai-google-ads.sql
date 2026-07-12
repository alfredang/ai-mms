-- Rename course C355 from "Full Google Ads Training" to "Agentic AI for Google
-- Ads" (2 days / 4 topics). Part of the Agentic AI series. name, overview,
-- topics, meta (title/description/keyword), cover, url_key. Price and duration
-- unchanged (700 SG / 15h). Store scope 0. Idempotent. No content line ends in
-- a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C355');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Agentic AI for Google Ads') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Drive more conversions on Google with Agentic AI for Google Ads. This hands-on 2-day course teaches you how to use AI agents and generative AI tools to research keywords, write ad copy, build and optimise campaigns, and automate your Google Ads workflow. Instead of managing everything manually, you will let AI agents handle keyword research, creative and bidding optimisation while you steer the strategy and budget.</p>
<p>Through practical projects, participants will use AI to research keywords and audiences, generate responsive search and display ad copy, structure campaigns and ad groups, and analyse and optimise performance and ROI. You will also learn to prompt effectively, keep brand consistency, and follow advertising and privacy best practices. By the end of the course, you will be able to plan, launch and scale high-performing Google Ads campaigns with an agentic AI workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Agentic AI for Google Ads</h3>
<ul>
<li>Introduction to Google Ads and Agentic AI</li>
<li>Setting Up AI Tools and Agents for Google Ads</li>
<li>Understanding Campaign Types, Objectives and Auctions</li>
<li>Effective Prompting for Keywords and Ads</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Keyword Research and Ad Copy with AI</h3>
<ul>
<li>AI-Powered Keyword and Audience Research</li>
<li>Generating Responsive Search and Display Ad Copy</li>
<li>Building Ad Groups and Match Types</li>
<li>Creating Assets and Extensions with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Building and Optimising Campaigns with AI</h3>
<ul>
<li>Structuring Campaigns and Budgets</li>
<li>Bidding Strategies and Smart Bidding</li>
<li>A/B Testing Ads and Landing Pages</li>
<li>Analysing Metrics, Quality Score and ROI with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Automating and Scaling Google Ads with AI Agents</h3>
<ul>
<li>Building Agentic Workflows for Campaign Management</li>
<li>Automating Optimisation, Reporting and Alerts</li>
<li>Scaling Winning Campaigns Profitably</li>
<li>Advertising, Compliance and Privacy Best Practices</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Agentic AI for Google Ads') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Drive more conversions with agentic AI for Google Ads. Research keywords, write ad copy and automate campaign optimisation with AI agents in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Agentic AI, Google Ads, AI Agents, PPC, Search Ads, Marketing Automation, Keyword Research, Ad Copy, Google Advertising, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C355-20260712-034550.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'agentic-ai-for-google-ads') ON DUPLICATE KEY UPDATE value = VALUES(value);
