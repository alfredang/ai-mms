-- 1280: WSQ Finance Courses (url_key 'wsq-finance-courses') — move two courses
-- out to WSQ Business and pin the requested order for the remaining seven.
--
-- MOVED OUT of Finance -> WSQ Business:
--   TGS-2025053923  WSQ - Corporate Law Compliance for Business Owners
--                   (ALREADY in WSQ Business at position 6 -> removal only)
--   TGS-2026061581  WSQ - Strategic Mergers and Acquisitions - Valuation, Risk,
--                   and Integration (NOT yet in WSQ Business -> genuinely added,
--                   appended after the pinned block from migration 1268)
--
-- No parent cleanup here. Finance (5) is a child of WSQ Finance & Accounting
-- (334), but 334 carries its own direct product rows beyond its children's union
-- (13 direct vs 18 in the child union), so it is NOT a 1265-style
-- sub-categories-only parent like WSQ Media & Marketing (72). Both courses keep
-- their 334 rows deliberately — compare 1267/1269/1272, where the parent WAS
-- scoped and stale rows had to be deleted.
--
-- Requested order for Finance:
--   1  TGS-2023038152  WSQ - Accounting for Non-Finance Managers
--   2  TGS-2025054485  WSQ - Tax Computations for Individuals and Organizations
--   3  TGS-2024049215  WSQ - Mastering Financial Ratio Analysis
--   4  TGS-2021002336  WSQ - Budgeting for Small and Medium Enterprises
--   5  TGS-2026064860  CASL - Financial Analysis for Small and Medium Enterprises
--   6  TGS-2026065050  CASL - Generative AI for Finance and Fintech
--   7  TGS-2026065049  CASL - Python Programming for Finance
--
-- All seven are TGS-, and Finance holds no C-prefix course, so the nightly sweep
-- has nothing to re-alphabetise and preserves TGS relative order — no
-- curated-allowlist entry needed. Business-key lookups only. Idempotent.

SET @fin := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-finance-courses' LIMIT 1);
SET @bz := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-business-courses' LIMIT 1);

-- 1. Ensure both courses are in WSQ Business ---------------------------------

SET @bz_pos := (SELECT COALESCE(MAX(position),0) FROM catalog_category_product WHERE category_id=@bz);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @bz, p.entity_id, @bz_pos + 1
FROM catalog_product_entity p
WHERE p.sku IN ('TGS-2025053923','TGS-2026061581') AND @bz IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @bz, p.entity_id, @bz_pos + 1, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku IN ('TGS-2025053923','TGS-2026061581') AND @bz IS NOT NULL
GROUP BY p.entity_id, s.store_id;

-- 2. Remove them from Finance -------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @fin AND @fin IS NOT NULL
  AND p.sku IN ('TGS-2025053923','TGS-2026061581');

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @fin AND @fin IS NOT NULL
  AND p.sku IN ('TGS-2025053923','TGS-2026061581');

-- 3. Pin the requested Finance order ------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023038152' THEN -7
  WHEN 'TGS-2025054485' THEN -6
  WHEN 'TGS-2024049215' THEN -5
  WHEN 'TGS-2021002336' THEN -4
  WHEN 'TGS-2026064860' THEN -3
  WHEN 'TGS-2026065050' THEN -2
  WHEN 'TGS-2026065049' THEN -1
END
WHERE cp.category_id = @fin AND @fin IS NOT NULL
  AND p.sku IN ('TGS-2023038152','TGS-2025054485','TGS-2024049215','TGS-2021002336',
                'TGS-2026064860','TGS-2026065050','TGS-2026065049');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023038152' THEN -7
  WHEN 'TGS-2025054485' THEN -6
  WHEN 'TGS-2024049215' THEN -5
  WHEN 'TGS-2021002336' THEN -4
  WHEN 'TGS-2026064860' THEN -3
  WHEN 'TGS-2026065050' THEN -2
  WHEN 'TGS-2026065049' THEN -1
END
WHERE i.category_id = @fin AND @fin IS NOT NULL
  AND p.sku IN ('TGS-2023038152','TGS-2025054485','TGS-2024049215','TGS-2021002336',
                'TGS-2026064860','TGS-2026065050','TGS-2026065049');
