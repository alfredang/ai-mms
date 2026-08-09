-- 901: Put "IBF - AI Assisted Python Programming for Finance" (TGS-2025052659)
-- first in the IBF category (url_key ibf-sts-funded-courses).
--
-- WHY THIS IS NOT JUST A POSITION PIN.
-- Category 350 carried its own sort overrides — default_sort_by='sku',
-- available_sort_by='name,sku' — so the listing sorted by SKU ASCENDING and
-- ignored position entirely. TGS-2025052659 is the numerically highest SKU in
-- the category, which is exactly why it rendered LAST. Writing positions alone
-- would have changed nothing on the storefront.
--
-- 385 of the ~392 categories carry NO sort override and inherit the store
-- default, which is 'position'. Only 350 and 292 override to 'sku'. This
-- migration removes 350's override so it behaves like every other category,
-- then pins the order.
--
-- Resulting order (WSQ/TGS- only; relative order of the other six preserved):
--   1  TGS-2025052659  IBF - AI Assisted Python Programming for Finance   (top)
--   2  TGS-2023018794  IBF - Machine Learning 101 for Financial Trading
--   3  TGS-2022602569  IBF - Financial Analysis for Non-Finance Managers
--   4  TGS-2022601648  IBF - Data Analytics and Deep Learning for Financial Services
--   5  TGS-2023017892  IBF - Financial Data Mining and Modeling with R
--   6  TGS-2022601875  IBF - Blockchain Smart Contract Programming for Financial Services
--   7  TGS-2022602057  IBF - Data Storytelling and Visualisation for Finance Services
--
-- All seven are TGS- (WSQ/IBF) products, and the nightly category-ordering
-- sweep preserves the relative order of TGS- products, so these pins persist
-- (same rationale as migrations 784 / 893).
--
-- Category flat is ENABLED, and the storefront reads the flat table in
-- preference to EAV, so the sort override must be cleared in BOTH places or the
-- page keeps sorting by SKU. The flat writes are information_schema-guarded per
-- store (SG=1, MY=2, GH=3) — a table absent on this instance is a clean no-op,
-- never a chain-aborting error. NEVER name a bare catalog_category_flat here.
--
-- Category and products resolved by business key (url_key / SKU) so this is
-- partner-safe; partner sites have no TGS- products and no IBF category, so it
-- is a no-op there. Idempotent.

SET @ibf_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'ibf-sts-funded-courses'
  LIMIT 1
);

SET @a_default_sort := (SELECT attribute_id FROM eav_attribute
  WHERE entity_type_id = 3 AND attribute_code = 'default_sort_by');
SET @a_available_sort := (SELECT attribute_id FROM eav_attribute
  WHERE entity_type_id = 3 AND attribute_code = 'available_sort_by');

-- 1) EAV: drop the category-level sort overrides so it inherits the store
--    default ('position'), matching the other 385 categories. All scopes.
DELETE FROM catalog_category_entity_varchar
WHERE entity_id = @ibf_category
  AND attribute_id = @a_default_sort
  AND @ibf_category IS NOT NULL;

DELETE FROM catalog_category_entity_text
WHERE entity_id = @ibf_category
  AND attribute_id = @a_available_sort
  AND @ibf_category IS NOT NULL;

-- 2) Flat mirror: the storefront reads this, so it must be cleared too.
--    information_schema-guarded per store; missing table => DO 0 (no-op).
SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_1') > 0
              AND @ibf_category IS NOT NULL,
  CONCAT("UPDATE catalog_category_flat_store_1 SET default_sort_by='position', ",
         "available_sort_by='position,name,sku' WHERE entity_id=", @ibf_category),
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_2') > 0
              AND @ibf_category IS NOT NULL,
  CONCAT("UPDATE catalog_category_flat_store_2 SET default_sort_by='position', ",
         "available_sort_by='position,name,sku' WHERE entity_id=", @ibf_category),
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @sql = IF((SELECT COUNT(*) FROM information_schema.TABLES
               WHERE TABLE_SCHEMA = DATABASE()
                 AND TABLE_NAME = 'catalog_category_flat_store_3') > 0
              AND @ibf_category IS NOT NULL,
  CONCAT("UPDATE catalog_category_flat_store_3 SET default_sort_by='position', ",
         "available_sort_by='position,name,sku' WHERE entity_id=", @ibf_category),
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 3) Pin the order. Base table (admin-facing source of truth).
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2025052659' THEN 1
  WHEN 'TGS-2023018794' THEN 2
  WHEN 'TGS-2022602569' THEN 3
  WHEN 'TGS-2022601648' THEN 4
  WHEN 'TGS-2023017892' THEN 5
  WHEN 'TGS-2022601875' THEN 6
  WHEN 'TGS-2022602057' THEN 7
END
WHERE cp.category_id = @ibf_category
  AND @ibf_category IS NOT NULL
  AND p.sku IN ('TGS-2025052659', 'TGS-2023018794', 'TGS-2022602569',
                'TGS-2022601648', 'TGS-2023017892', 'TGS-2022601875',
                'TGS-2022602057');

-- 4) Pin the order. Index table — what the listing actually reads, every store.
UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2025052659' THEN 1
  WHEN 'TGS-2023018794' THEN 2
  WHEN 'TGS-2022602569' THEN 3
  WHEN 'TGS-2022601648' THEN 4
  WHEN 'TGS-2023017892' THEN 5
  WHEN 'TGS-2022601875' THEN 6
  WHEN 'TGS-2022602057' THEN 7
END
WHERE i.category_id = @ibf_category
  AND @ibf_category IS NOT NULL
  AND p.sku IN ('TGS-2025052659', 'TGS-2023018794', 'TGS-2022602569',
                'TGS-2022601648', 'TGS-2023017892', 'TGS-2022601875',
                'TGS-2022602057');
