-- 1140: Curated WSQ order for the Relational SQL category
--       (/relational-sql-databases.html), admin-requested 2026-08-27:
--
--   1. WSQ - SQL Fundamental for Beginners                     TGS-2020505790
--   2. WSQ - AI Vibe Coding for SQL                            TGS-2021002619
--   3. WSQ - Microsoft Azure Data Fundamentals (DP-900)        TGS-2023036641
--   4. WSQ - Administering Microsoft Azure SQL Solutions       TGS-2024048319
--      (DP-300)
--
-- 784/785/786 pattern: the daily category-ordering sweep (and 545-style
-- reorders like 1139) preserve the RELATIVE order of TGS- products, so
-- pinning positions 0..3 here is durable — only non-WSQ curated pins are
-- flattened. Non-WSQ rows (C1154, C1415) keep their alphabetical slots after
-- the WSQ block. SKUs verified against LIVE SG prod index 2026-08-27.
--
-- Category resolved by url_key (business key; ids can differ per instance).
-- Both tables written: catalog_category_product (admin) and
-- catalog_category_product_index (what the storefront listing reads).
-- Partner-safe: TGS- SKUs exist only on SG, so the JOINs match zero rows on
-- MY/GH. Idempotent.

SET @cat := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'relational-sql-databases'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2020505790' THEN 0
  WHEN 'TGS-2021002619' THEN 1
  WHEN 'TGS-2023036641' THEN 2
  WHEN 'TGS-2024048319' THEN 3
END
WHERE cp.category_id = @cat
  AND p.sku IN ('TGS-2020505790', 'TGS-2021002619', 'TGS-2023036641', 'TGS-2024048319');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2020505790' THEN 0
  WHEN 'TGS-2021002619' THEN 1
  WHEN 'TGS-2023036641' THEN 2
  WHEN 'TGS-2024048319' THEN 3
END
WHERE i.category_id = @cat
  AND p.sku IN ('TGS-2020505790', 'TGS-2021002619', 'TGS-2023036641', 'TGS-2024048319');
