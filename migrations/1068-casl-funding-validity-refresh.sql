-- 1068: Refresh the Funding Validity window for the 40 CASL (Non-WSQ TPG)
-- course registrations from the Aug 2026 "CASL_Courses" SSG export.
--
-- 22 of the 40 carried stale pre-registration windows (e.g. TGS-2026064172
-- start 2020-09-01, end 2026-08-31 - already lapsed), so the storefront
-- "Funding Validity" card (view.phtml section 6b) advertised an expired or
-- wrong window. The other 18 already matched the export and are omitted.
--
-- Writes news_from_date / news_to_date at store 0 - since migrations 875/876
-- these attributes ARE the Funding Validity window on TGS- SKUs (they remain
-- the legacy class-date mirror on C- SKUs, which this migration never
-- touches: every row is keyed by an explicit TGS- SKU).
--
-- The 12 courses carrying a legacy per-course course_<sku>_funding_validity
-- cms/block override are NOT in this set - verified against prod that their
-- block copy already matches the export, so no block edits are needed and no
-- write here is shadowed by a block.
--
-- Idempotent via ON DUPLICATE KEY UPDATE on UNQ (entity_id, attribute_id,
-- store_id). Keyed by SKU, so partner instances (MY/GH carry no TGS- SKUs)
-- are a guaranteed no-op. ASCII-only values - no UTF-8 sanitisation needed.

SET @fv_start := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'news_from_date');
SET @fv_end   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'news_to_date');

-- Funding Validity START
INSERT INTO catalog_product_entity_datetime (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @fv_start, 0, e.entity_id, v.ds
FROM (
  SELECT 'TGS-2026064172' AS sku, '2026-08-30 00:00:00' AS ds, '2027-05-31 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064174' AS sku, '2026-08-05 00:00:00' AS ds, '2027-08-04 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064176' AS sku, '2026-08-15 00:00:00' AS ds, '2027-08-14 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064180' AS sku, '2026-08-04 00:00:00' AS ds, '2027-08-03 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064181' AS sku, '2026-08-19 00:00:00' AS ds, '2027-08-18 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064534' AS sku, '2026-08-10 00:00:00' AS ds, '2027-08-09 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064535' AS sku, '2026-08-16 00:00:00' AS ds, '2027-08-15 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064536' AS sku, '2026-08-09 00:00:00' AS ds, '2027-08-08 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064608' AS sku, '2026-08-05 00:00:00' AS ds, '2027-08-04 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064708' AS sku, '2026-08-16 00:00:00' AS ds, '2028-08-15 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064709' AS sku, '2026-08-30 00:00:00' AS ds, '2027-08-29 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064710' AS sku, '2026-08-09 00:00:00' AS ds, '2027-08-08 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064712' AS sku, '2026-08-30 00:00:00' AS ds, '2027-08-29 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064713' AS sku, '2026-08-05 00:00:00' AS ds, '2027-08-04 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064714' AS sku, '2026-08-01 00:00:00' AS ds, '2027-07-31 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064715' AS sku, '2026-08-09 00:00:00' AS ds, '2027-08-08 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064717' AS sku, '2026-08-30 00:00:00' AS ds, '2027-08-29 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064718' AS sku, '2026-08-19 00:00:00' AS ds, '2027-08-18 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064720' AS sku, '2026-07-28 00:00:00' AS ds, '2028-07-27 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064859' AS sku, '2026-08-30 00:00:00' AS ds, '2027-08-29 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026065048' AS sku, '2026-08-09 00:00:00' AS ds, '2027-08-08 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026065049' AS sku, '2026-08-09 00:00:00' AS ds, '2027-08-08 00:00:00' AS de
) v
JOIN catalog_product_entity e ON e.sku = v.sku
WHERE @fv_start IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Funding Validity END
INSERT INTO catalog_product_entity_datetime (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @fv_end, 0, e.entity_id, v.de
FROM (
  SELECT 'TGS-2026064172' AS sku, '2026-08-30 00:00:00' AS ds, '2027-05-31 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064174' AS sku, '2026-08-05 00:00:00' AS ds, '2027-08-04 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064176' AS sku, '2026-08-15 00:00:00' AS ds, '2027-08-14 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064180' AS sku, '2026-08-04 00:00:00' AS ds, '2027-08-03 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064181' AS sku, '2026-08-19 00:00:00' AS ds, '2027-08-18 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064534' AS sku, '2026-08-10 00:00:00' AS ds, '2027-08-09 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064535' AS sku, '2026-08-16 00:00:00' AS ds, '2027-08-15 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064536' AS sku, '2026-08-09 00:00:00' AS ds, '2027-08-08 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064608' AS sku, '2026-08-05 00:00:00' AS ds, '2027-08-04 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064708' AS sku, '2026-08-16 00:00:00' AS ds, '2028-08-15 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064709' AS sku, '2026-08-30 00:00:00' AS ds, '2027-08-29 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064710' AS sku, '2026-08-09 00:00:00' AS ds, '2027-08-08 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064712' AS sku, '2026-08-30 00:00:00' AS ds, '2027-08-29 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064713' AS sku, '2026-08-05 00:00:00' AS ds, '2027-08-04 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064714' AS sku, '2026-08-01 00:00:00' AS ds, '2027-07-31 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064715' AS sku, '2026-08-09 00:00:00' AS ds, '2027-08-08 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064717' AS sku, '2026-08-30 00:00:00' AS ds, '2027-08-29 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064718' AS sku, '2026-08-19 00:00:00' AS ds, '2027-08-18 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064720' AS sku, '2026-07-28 00:00:00' AS ds, '2028-07-27 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026064859' AS sku, '2026-08-30 00:00:00' AS ds, '2027-08-29 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026065048' AS sku, '2026-08-09 00:00:00' AS ds, '2027-08-08 00:00:00' AS de
  UNION ALL SELECT 'TGS-2026065049' AS sku, '2026-08-09 00:00:00' AS ds, '2027-08-08 00:00:00' AS de
) v
JOIN catalog_product_entity e ON e.sku = v.sku
WHERE @fv_end IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);
