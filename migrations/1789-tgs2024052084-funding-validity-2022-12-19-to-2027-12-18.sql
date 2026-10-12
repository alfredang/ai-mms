-- 1789: Funding Validity window for TGS-2024052084 (WSQ - Data Quality
-- Management Framework) -> 2022-12-19 .. 2027-12-18 (was 2024-12-27 ..
-- 2026-12-26).
--
-- news_from_date / news_to_date at store 0 ARE the Funding Validity window on
-- TGS- SKUs (migrations 875/876). No course_<sku>_funding_validity cms/block
-- override exists for this course, so nothing shadows the write.
--
-- Idempotent (ON DUPLICATE KEY UPDATE). Keyed by TGS- SKU, so partner
-- instances (MY/GH carry no TGS- SKUs) are a no-op.

SET @fv_start := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'news_from_date');
SET @fv_end   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'news_to_date');

INSERT INTO catalog_product_entity_datetime (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @fv_start, 0, e.entity_id, '2022-12-19 00:00:00'
FROM catalog_product_entity e
WHERE TRIM(e.sku) = 'TGS-2024052084' AND @fv_start IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_datetime (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @fv_end, 0, e.entity_id, '2027-12-18 00:00:00'
FROM catalog_product_entity e
WHERE TRIM(e.sku) = 'TGS-2024052084' AND @fv_end IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
