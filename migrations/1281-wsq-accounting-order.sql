-- 1281: WSQ Accounting Courses (url_key 'wsq-accounting-courses') — move one
-- course out to WSQ Business and pin the requested order for the remaining six.
--
-- MOVED OUT: TGS-2025053923 "WSQ - Corporate Law Compliance for Business Owners"
-- -> WSQ Business. It is ALREADY a member there (position 6, pinned by 1268), so
-- this is a removal from Accounting only; the INSERT IGNORE is a per-instance
-- safety net. Note 1280 removed the same course from WSQ Finance — it sat in
-- both Finance and Accounting.
--
-- No parent cleanup. Accounting (442) is a child of WSQ Finance & Accounting
-- (334), but 334 carries its own direct rows beyond its children's union
-- (13 direct vs 17 in the child union), so it is NOT a 1265-style
-- sub-categories-only parent like WSQ Media & Marketing (72). Corporate Law
-- keeps its 334 row deliberately — same call as 1280.
--
-- Requested order:
--   1  TGS-2023038152  WSQ - Accounting for Non-Finance Managers
--   2  TGS-2025054485  WSQ - Tax Computations for Individuals and Organizations
--   3  TGS-2026064181  CASL - Quickbooks Accounting System for Small and Medium Enterprises
--   4  TGS-2023018989  WSQ - Advanced Transactional Accounting with Quickbooks Online
--   5  TGS-2026064172  CASL - Xero Essentials for SMEs
--   6  TGS-2023020565  WSQ - Advanced Transactional Accounting with Xero
--
-- All six are TGS- and the category holds no C-prefix course, so the nightly
-- sweep has nothing to re-alphabetise and preserves TGS relative order — no
-- curated-allowlist entry needed. Business-key lookups only. Idempotent.

SET @acc := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-accounting-courses' LIMIT 1);
SET @bz := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-business-courses' LIMIT 1);

-- 1. Safety net: ensure Corporate Law is in WSQ Business ----------------------

SET @bz_pos := (SELECT COALESCE(MAX(position),0) FROM catalog_category_product WHERE category_id=@bz);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @bz, p.entity_id, @bz_pos + 1
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2025053923' AND @bz IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @bz, p.entity_id, @bz_pos + 1, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'TGS-2025053923' AND @bz IS NOT NULL
GROUP BY p.entity_id, s.store_id;

-- 2. Remove it from Accounting ------------------------------------------------

DELETE cp FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE cp.category_id = @acc AND @acc IS NOT NULL AND p.sku = 'TGS-2025053923';

DELETE i FROM catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
WHERE i.category_id = @acc AND @acc IS NOT NULL AND p.sku = 'TGS-2025053923';

-- 3. Pin the requested order --------------------------------------------------

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2023038152' THEN -6
  WHEN 'TGS-2025054485' THEN -5
  WHEN 'TGS-2026064181' THEN -4
  WHEN 'TGS-2023018989' THEN -3
  WHEN 'TGS-2026064172' THEN -2
  WHEN 'TGS-2023020565' THEN -1
END
WHERE cp.category_id = @acc AND @acc IS NOT NULL
  AND p.sku IN ('TGS-2023038152','TGS-2025054485','TGS-2026064181',
                'TGS-2023018989','TGS-2026064172','TGS-2023020565');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2023038152' THEN -6
  WHEN 'TGS-2025054485' THEN -5
  WHEN 'TGS-2026064181' THEN -4
  WHEN 'TGS-2023018989' THEN -3
  WHEN 'TGS-2026064172' THEN -2
  WHEN 'TGS-2023020565' THEN -1
END
WHERE i.category_id = @acc AND @acc IS NOT NULL
  AND p.sku IN ('TGS-2023038152','TGS-2025054485','TGS-2026064181',
                'TGS-2023018989','TGS-2026064172','TGS-2023020565');
