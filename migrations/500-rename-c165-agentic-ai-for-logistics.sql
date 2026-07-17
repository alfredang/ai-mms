-- Rename course C165 from "AI for Logistics" to "Agentic AI for Logistics".
-- The course body (overview + topics) is already agentic-oriented from an
-- earlier refresh, so only the title-bearing fields change: name, url_key,
-- meta_title, meta_keyword, image labels, the one short_description sentence
-- that still says "AI for Logistics", and course_image_url (cover re-rendered
-- 2026-07-17 with the new title, uploaded to R2). meta_description already
-- leads with agentic AI and is left untouched. Price/duration/topics unchanged.
-- Clears per-store overrides of the rewritten attributes so partner store
-- scopes can't shadow store 0, and drops url_path at every scope so the
-- Catalog URL Rewrites indexer regenerates the new URL.
-- Guarded with @e IS NOT NULL so it is a no-op on sites without C165.
-- Store scope 0. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='C165');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');
SET @a_il    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='image_label');
SET @a_sil   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='small_image_label');
SET @a_til   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='thumbnail_label');
SET @a_ciu   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='course_image_url');
SET @a_up    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_path');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'Agentic AI for Logistics' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>Transform your logistics operations with Agentic AI for Logistics. This hands-on 1-day course shows you how agentic AI &mdash; AI agents that can plan, decide and act on your behalf &mdash; improves logistics efficiency, shipment tracking and operations monitoring. You will learn how AI agents optimise routes and delivery schedules, streamline warehouse and inventory operations, forecast demand and cut manual coordination work across the supply chain.</p>
<p>Through practical exercises, participants will apply AI agents to real logistics scenarios &mdash; planning deliveries, tracking shipments in real time, building monitoring dashboards, and setting up automated alerts that flag delays and exceptions before they become problems. You will also learn to review and validate agent decisions so your operations stay reliable and in control. By the end of the course, you will be able to apply agentic AI to run a more efficient, visible and responsive logistics operation.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'Agentic AI for Logistics' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'Agentic AI for Logistics, Agentic AI, AI Agents, Logistics Efficiency, Shipment Tracking, Fleet Monitoring, Route Optimisation, Warehouse Automation, Supply Chain AI, Predictive Maintenance, Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'agentic-ai-for-logistics' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- New cover rendered from the new title (no funding chips — C165 carries no
-- funding-badge tags), uploaded to R2 2026-07-17
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_ciu, 0, @e, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C165-20260717-164356.png' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_il, 0, @e, 'Agentic AI for Logistics' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sil, 0, @e, 'Agentic AI for Logistics' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_til, 0, @e, 'Agentic AI for Logistics' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_url, @a_il, @a_sil, @a_til, @a_ciu);
DELETE FROM catalog_product_entity_text
WHERE entity_id=@e AND @e IS NOT NULL AND store_id<>0 AND attribute_id IN (@a_short, @a_mk);

-- Stale url_path rows point at the old ai-for-logistics URL; drop them at
-- every scope so the Catalog URL Rewrites indexer regenerates
DELETE FROM catalog_product_entity_varchar
WHERE entity_id=@e AND @e IS NOT NULL AND attribute_id=@a_up AND @a_up IS NOT NULL;
