-- Rename course C526 from "Complete Facebook Marketing & Advertising Training"
-- to "Agentic AI for Facebook Marketing" (2 days / 4 topics). Part of the Agentic
-- AI series. name, overview, topics, meta (title/description/keyword), cover,
-- url_key. Price and duration unchanged (700 SG / 15h). Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C526');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Agentic AI for Facebook Marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Grow your reach and sales on Facebook with Agentic AI for Facebook Marketing. This hands-on 2-day course teaches you how to use AI agents and generative AI tools to create content, write ad copy, build and optimise ad campaigns, and automate your Facebook marketing. Instead of managing everything manually, you will let AI agents research audiences, draft creative and run optimisation workflows while you steer the strategy.</p>
<p>Through practical projects, participants will use AI to plan content and campaigns, generate posts, ad copy and creatives, set up and target Facebook ad campaigns, and analyse and optimise performance. You will also learn to prompt effectively, keep brand consistency, and follow advertising and privacy best practices. By the end of the course, you will be able to plan, create and scale high-performing Facebook marketing and ad campaigns with an agentic AI workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Agentic AI for Facebook Marketing</h3>
<ul>
<li>Introduction to Facebook Marketing and Agentic AI</li>
<li>Setting Up AI Tools and Agents for Facebook</li>
<li>Understanding Audiences, Objectives and the Ads Ecosystem</li>
<li>Effective Prompting for Content and Ads</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Content Creation and Ad Copy with AI</h3>
<ul>
<li>Generating Post Ideas, Captions and Ad Copy</li>
<li>Creating Images, Carousels and Video Creatives with AI</li>
<li>Planning a Content Calendar</li>
<li>Keeping Brand Voice and Consistency</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Building and Optimising Ad Campaigns with AI</h3>
<ul>
<li>Setting Up Campaigns, Ad Sets and Targeting</li>
<li>Audience Research and Segmentation with AI</li>
<li>A/B Testing Creatives and Copy</li>
<li>Analysing Metrics and Optimising with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Automating and Scaling Facebook Marketing with AI Agents</h3>
<ul>
<li>Building Agentic Workflows for Content and Ads</li>
<li>Automating Posting, Responses and Reporting</li>
<li>Scaling Winning Campaigns</li>
<li>Advertising, Compliance and Privacy Best Practices</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Agentic AI for Facebook Marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Grow your Facebook reach and sales with agentic AI. Create content, write ad copy and automate campaigns with AI agents in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Agentic AI, Facebook Marketing, Facebook Ads, AI Agents, Marketing Automation, Ad Copy, Social Media, Meta Ads, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C526-20260712-034406.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'agentic-ai-for-facebook-marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);
