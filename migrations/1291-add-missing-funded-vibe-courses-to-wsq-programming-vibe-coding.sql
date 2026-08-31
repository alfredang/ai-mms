-- 1291: Add the 8 funded (TGS-) courses that are in "AI Vibe Coding Series"
-- (url_key 'ai-vibe-coding-series') but were missing from "WSQ Programming &
-- Vibe Coding" (url_key
-- 'wsq-programming-vibe-coding-courses-tertiary-courses-singapore').
--
-- All 8 are live and enabled (status=1) and already render on the series page;
-- they simply had no catalog_category_product row for the WSQ category, so the
-- funded listing was incomplete. Same failure mode as 1264/1279/1289.
--
--   TGS-2019504643  WSQ  - AI Vibe Coding for Data Analytics
--   TGS-2021002619  WSQ  - AI Vibe Coding for SQL
--   TGS-2021009338  WSQ  - Develop Blockchain and Web3 App with Vibe Coding
--   TGS-2024045802  WSQ  - AI Vibe Coding for Data Mining and Modeling
--   TGS-2025052659  IBF  - AI Assisted Python Programming for Finance
--   TGS-2025052674  WSQ  - AI Vibe Coding for Game Development
--   TGS-2026064175  CASL - Build Your Own eCommerce Store with AI Vibe Coding
--   TGS-2026064720  CASL - AI Vibe Coding with PyTorch
--
-- Positions are appended after the existing MAX(position) as POSITIVE values
-- (never negative — a full reindex zeroes negative positions). The category is
-- not on the curated allowlist, so the nightly CategoryOrdering sweep will
-- normalise the final order (funded TGS- first, alphabetical). Every row here
-- is TGS-, so the funded-first rule cannot be broken by this change.
--
-- Also mirrors into catalog_category_product_index so the courses appear before
-- the next reindex. Business-key (SKU / url_key) lookups only. Idempotent.
-- Safe on partner sites: the category and these SKUs do not exist there, so
-- every statement matches zero rows.

SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'wsq-programming-vibe-coding-courses-tertiary-courses-singapore'
  LIMIT 1);

-- MySQL 1093: cannot read the target table in a subquery, so snapshot the
-- current max position into a variable first.
SET @base := (SELECT COALESCE(MAX(position), 0)
  FROM catalog_category_product WHERE category_id = @cat);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, p.entity_id, @base + s.ord
FROM catalog_product_entity p
JOIN (
  SELECT 'TGS-2019504643' AS sku, 1 AS ord UNION ALL
  SELECT 'TGS-2021002619', 2 UNION ALL
  SELECT 'TGS-2021009338', 3 UNION ALL
  SELECT 'TGS-2024045802', 4 UNION ALL
  SELECT 'TGS-2025052659', 5 UNION ALL
  SELECT 'TGS-2025052674', 6 UNION ALL
  SELECT 'TGS-2026064175', 7 UNION ALL
  SELECT 'TGS-2026064720', 8
) s ON s.sku = p.sku
WHERE @cat IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, cp.product_id, cp.position, 1, i.store_id, MAX(i.visibility)
FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
JOIN catalog_category_product_index i ON i.product_id = cp.product_id
WHERE cp.category_id = @cat AND @cat IS NOT NULL
  AND p.sku IN ('TGS-2019504643','TGS-2021002619','TGS-2021009338',
                'TGS-2024045802','TGS-2025052659','TGS-2025052674',
                'TGS-2026064175','TGS-2026064720')
GROUP BY cp.product_id, cp.position, i.store_id;
