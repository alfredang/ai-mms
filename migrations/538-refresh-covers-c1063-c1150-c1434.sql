-- Refresh course covers so the rendered title matches the current course name
-- for three NON-WSQ (C-prefix) courses whose rename migrations deferred the
-- cover re-render (their 499-batch cover still carried the OLD title):
--   C1063  Power Automate Masterclass   (was "Microsoft Power Automate Training")
--   C1150  UIPath RPA Masterclass       (was "RPA with UIPath")
--   C1434  AI Agent with Openclaw       (was "Build Autonomous AI Agent with Openclaw")
-- Covers re-rendered 2026-07-18 from the live store-0 name (no funding chips —
-- none of the three carry funding-badge tags), uploaded to R2, and verified
-- HTTP 200 / valid 1600x900 PNG. Also aligns image_label/small_image_label/
-- thumbnail_label to the new name and clears store-scoped overrides of those 4
-- attributes so no per-store row shadows the new cover.
-- Map-table + JOIN pattern (same as 499): SKUs absent on a partner DB are
-- skipped (partners carry M-prefix SKUs, not these C-prefix ones). WSQ (TGS-)
-- courses are intentionally NOT touched. Store scope 0. Idempotent.

DROP TABLE IF EXISTS mmd_cover_refresh_538;

CREATE TABLE mmd_cover_refresh_538 (
  sku VARCHAR(64) NOT NULL PRIMARY KEY,
  url VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO mmd_cover_refresh_538 (sku, url, name) VALUES
('C1063','https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1063-20260717-184750.png','Power Automate Masterclass'),
('C1150','https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1150-20260717-184750.png','UIPath RPA Masterclass'),
('C1434','https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C1434-20260717-184750.png','AI Agent with Openclaw');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, e.entity_id, m.url
FROM mmd_cover_refresh_538 m
JOIN catalog_product_entity e ON e.sku = m.sku
JOIN eav_attribute a ON a.entity_type_id = 4 AND a.attribute_code = 'course_image_url'
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, e.entity_id, m.name
FROM mmd_cover_refresh_538 m
JOIN catalog_product_entity e ON e.sku = m.sku
JOIN eav_attribute a ON a.entity_type_id = 4 AND a.attribute_code IN ('image_label','small_image_label','thumbnail_label')
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE v FROM catalog_product_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
  AND a.attribute_code IN ('course_image_url','image_label','small_image_label','thumbnail_label')
JOIN catalog_product_entity e ON e.entity_id = v.entity_id
JOIN mmd_cover_refresh_538 m ON m.sku = e.sku
WHERE v.store_id <> 0;

DROP TABLE IF EXISTS mmd_cover_refresh_538;
