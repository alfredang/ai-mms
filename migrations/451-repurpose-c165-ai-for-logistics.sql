-- Repurpose course C165 from "SC-5001 Configure SIEM Security Operations Using
-- Microsoft Sentinel" to "AI for Logistics" (1 day / 2 topics — agentic AI for
-- logistics efficiency, tracking and monitoring). name, overview, topics, meta,
-- duration 7.5h, cover, url_key. Moves it out of the security/Microsoft
-- categories into "AI Applications Series" (categories resolved by NAME so it
-- is partner-safe; ids differ per site). Price unchanged ($350 SG).
-- Deactivates the stale Sentinel brochure block. Clears per-store overrides of
-- the rewritten attributes so partner store scopes can't shadow store 0.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C165');
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
VALUES (4, @a_name, 0, @e, 'AI for Logistics') ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_short, 0, @e, '<p>Transform your logistics operations with AI for Logistics. This hands-on 1-day course shows you how agentic AI &mdash; AI agents that can plan, decide and act on your behalf &mdash; improves logistics efficiency, shipment tracking and operations monitoring. You will learn how AI agents optimise routes and delivery schedules, streamline warehouse and inventory operations, forecast demand and cut manual coordination work across the supply chain.</p>
<p>Through practical exercises, participants will apply AI agents to real logistics scenarios &mdash; planning deliveries, tracking shipments in real time, building monitoring dashboards, and setting up automated alerts that flag delays and exceptions before they become problems. You will also learn to review and validate agent decisions so your operations stay reliable and in control. By the end of the course, you will be able to apply agentic AI to run a more efficient, visible and responsive logistics operation.</p>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_desc, 0, @e, '<h3 class="course-topic-h3">Topic 1 Agentic AI for Logistics Efficiency</h3>
<ul>
<li>Introduction to AI and Agentic AI in Logistics</li>
<li>Route Planning and Delivery Optimisation with AI Agents</li>
<li>Warehouse Operations and Inventory Automation</li>
<li>Demand Forecasting and Resource Planning with AI</li>
</ul>
<h3 class="course-topic-h3">Topic 2 Agentic AI for Tracking and Monitoring</h3>
<ul>
<li>Real-Time Shipment Tracking with AI Agents</li>
<li>Fleet and Asset Monitoring Dashboards</li>
<li>Automated Alerts, Exception Handling and Delay Management</li>
<li>Predictive Maintenance and Continuous Performance Monitoring</li>
</ul>')
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mt, 0, @e, 'AI for Logistics') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_md, 0, @e, 'Improve logistics efficiency, tracking and monitoring with agentic AI. Learn AI agents for route optimisation, warehouse operations, real-time shipment tracking and automated alerts in this hands-on 1-day course at Tertiary Courses Singapore.')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_mk, 0, @e, 'AI for Logistics, Agentic AI, Logistics Efficiency, Shipment Tracking, Fleet Monitoring, Route Optimisation, Warehouse Automation, Supply Chain AI, Predictive Maintenance, Singapore')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_dur, 0, @e, '7.5') ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_img, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C165-20260714-004753.png')
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
VALUES (4, @a_url, 0, @e, 'ai-for-logistics') ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_dur, @a_img, @a_url);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

DELETE cp FROM catalog_category_product cp
JOIN catalog_category_entity_varchar v ON v.entity_id=cp.category_id AND v.store_id=0
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE cp.product_id=@e AND v.value IN ('Microsoft', 'Microsoft Certification Exam Prep', 'Microsoft 365 Certification', 'Cyber Security', 'CyberSecurity & Threat Analysis');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT v.entity_id, @e, 0 FROM catalog_category_entity_varchar v
JOIN eav_attribute ca ON ca.attribute_id=v.attribute_id AND ca.entity_type_id=3 AND ca.attribute_code='name'
WHERE v.store_id=0 AND v.value = 'AI Applications Series' AND @e IS NOT NULL;

UPDATE cms_block SET is_active = 0 WHERE identifier = 'course_C165_brochure';
