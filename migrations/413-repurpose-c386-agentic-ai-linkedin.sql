-- Rename course C386 from "Master LinkedIn to Grow Your Business Network and
-- Influence" to "Agentic AI for Linkedin Marketing" (2 days / 4 topics). Part of
-- the Agentic AI series. name, overview, topics, meta (title/description/keyword),
-- cover, url_key. Price and duration unchanged (700 SG / 15h). Store scope 0.
-- Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C386');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Agentic AI for Linkedin Marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Grow your brand and pipeline on LinkedIn with Agentic AI for Linkedin Marketing. This hands-on 2-day course teaches you how to use AI agents and generative AI tools to create content, build your personal brand, generate leads and automate outreach on LinkedIn. Instead of doing everything manually, you will let AI agents research prospects, draft posts and messages, and run engagement workflows while you focus on strategy and relationships.</p>
<p>Through practical projects, participants will use AI to plan a content calendar, write posts and articles, optimise their profile, research and segment prospects, and design automated outreach and nurture sequences. You will also learn to prompt effectively, keep an authentic voice, and stay within LinkedIn best practices and etiquette. By the end of the course, you will be able to grow your network, influence and lead generation on LinkedIn with an agentic AI workflow.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Getting Started with Agentic AI for LinkedIn Marketing</h3>
<ul>
<li>Introduction to LinkedIn Marketing and Agentic AI</li>
<li>Setting Up AI Tools and Agents for LinkedIn</li>
<li>Optimising Your Profile and Personal Brand with AI</li>
<li>Effective Prompting for LinkedIn Content and Outreach</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Content Creation and Personal Branding with AI</h3>
<ul>
<li>Generating Post Ideas, Hooks and Articles with AI</li>
<li>Planning a Content Calendar and Series</li>
<li>Creating Visuals and Carousels with AI</li>
<li>Keeping an Authentic Voice and Consistent Brand</li>
</ul>
<h3 class="course-topic-h3">Topic 3 Lead Generation and Outreach with AI Agents</h3>
<ul>
<li>Researching and Segmenting Prospects with AI</li>
<li>Personalised Connection Requests and Messages</li>
<li>Designing Outreach and Nurture Sequences</li>
<li>Social Selling Best Practices and Etiquette</li>
</ul>
<h3 class="course-topic-h3">Topic 4 Automating and Scaling LinkedIn with AI Agents</h3>
<ul>
<li>Building Agentic Workflows for Content and Engagement</li>
<li>Automating Posting, Comments and Follow-Ups</li>
<li>Measuring Performance and Iterating with AI</li>
<li>Scaling Your LinkedIn Strategy Responsibly</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Agentic AI for Linkedin Marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Grow your LinkedIn brand and leads with agentic AI. Create content, generate leads and automate outreach with AI agents in this hands-on 2-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Agentic AI, LinkedIn Marketing, AI Agents, Social Selling, Lead Generation, Personal Branding, Marketing Automation, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C386-20260712-034317.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'agentic-ai-for-linkedin-marketing') ON DUPLICATE KEY UPDATE value = VALUES(value);
