-- Repurpose course C20 from "HTML5 and CSS3 Essential Training" to
-- "Manage Multi Agents with Paperclip" (1 day / 2 topics — orchestrating a team
-- of AI agents with the open-source Paperclip platform, https://paperclip.ing/).
-- name, overview, topics, meta, duration 7.5h, cover, url_key. Moves it out of
-- the web-design categories into "AI Applications Series" (categories resolved
-- by NAME so it is partner-safe; ids differ per site). Price unchanged ($350 SG).
-- Points the Funding block at WSQ - Build a Human-AI Workforce with Autonomous
-- AI Agents (validated 200 on www.tertiarycourses.com.sg). Clears per-store
-- overrides of the rewritten attributes so partner store scopes can't shadow
-- store 0. Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C20');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='duration');
SET @a_img   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_name, 0, @e, 'Manage Multi Agents with Paperclip') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Move beyond single-prompt AI and learn to run a coordinated team of AI agents. Manage Multi Agents with Paperclip is a hands-on 1-day course on Paperclip, the open-source platform for orchestrating a workforce of AI agents. You will set up your own self-hosted Paperclip instance, build an agent org chart with defined roles and reporting lines, and connect model-agnostic agent runtimes such as Claude, Codex, Gemini and Cursor so your agents work together on real business objectives.</p>
<p>Through practical exercises, participants will assign work through Paperclip&rsquo;s ticket system, align every agent task to business goals and missions, schedule agents with heartbeats, and keep spending in control with per-agent budgets that pause agents automatically at their limits. You will also learn to govern your agent team responsibly &mdash; approving hires, reviewing strategies, tracing decisions through immutable audit logs, and overriding or terminating agents when needed. By the end of the course, you will be able to manage a multi-agent AI team that delivers real work, on goal and on budget.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Building Your AI Agent Team with Paperclip</h3>
<ul>
<li>Introduction to Multi-Agent AI and the Paperclip Platform</li>
<li>Installing and Self-Hosting Paperclip</li>
<li>Building the Agent Org Chart with Roles, Titles and Reporting Lines</li>
<li>Connecting Agent Runtimes such as Claude, Codex, Gemini and Cursor</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Running and Governing Multi-Agent Operations</h3>
<ul>
<li>Aligning Agent Work to Business Goals and Missions</li>
<li>Managing Tasks with Tickets and Heartbeat Scheduling</li>
<li>Controlling Costs with Per-Agent Budgets and Spend Tracking</li>
<li>Governance with Audit Logs, Approvals, Overrides and Agent Termination</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'Manage Multi Agents with Paperclip') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Learn to orchestrate a team of AI agents with Paperclip, the open-source multi-agent management platform. Build agent org charts, assign tickets, set budgets and govern agent operations in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'Paperclip, Multi Agent Management, AI Agents, Agent Orchestration, Agentic AI, AI Agent Teams, Autonomous Agents, Agent Governance, AI Workforce, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C20-20260716-162623.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'manage-multi-agents-with-paperclip') ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_dur, @a_img, @a_url);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

DELETE cp FROM catalog_category_product cp
JOIN catalog_category_entity_varchar v ON v.entity_id=cp.category_id AND v.store_id=0
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE cp.product_id=@e AND v.value IN ('Web Development', 'HTML & CSS');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0 FROM catalog_category_entity_varchar v
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE v.store_id=0 AND v.value = 'AI Applications Series' AND @e IS NOT NULL;

UPDATE cms_block
SET content = '<h2>Funding and Grant Applications</h2>
<p>No funding is available for this course</p>
<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html" title="WSQ - Build a Human-AI Workforce with Autonomous AI Agents">WSQ - Build a Human-AI Workforce with Autonomous AI Agents</a></span></p>'
WHERE identifier = 'course_C20_funding_and_grant';
