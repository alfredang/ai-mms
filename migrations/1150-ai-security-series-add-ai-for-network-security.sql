-- 1150: List WSQ - AI for Network Security (TGS-2024051414) on the AI Security
--       Series category (/ai-security-series.html), admin-requested 2026-08-29,
--       placed immediately AFTER "WSQ - AI for Cyber Security".
--
-- Placement note: TWO courses in this category are named "AI for Cyber Security" --
-- the WSQ TGS-2023039177 and the non-WSQ C434. The category follows the house
-- convention of a curated WSQ block first (pinned by 1142/1143), then the non-WSQ
-- C-prefix rows. The new course is WSQ, so it goes after the WSQ one; slotting it
-- after C434 would drop a WSQ course into the middle of the non-WSQ block.
--
-- Extends the 1142 curated WSQ order by inserting at position 3 and shifting the
-- rest of the block down one:
--
--   0. WSQ - AI Security for Autonomous AI Agents           TGS-2025060473
--   1. WSQ - AI Security Awareness                          TGS-2025060472
--   2. WSQ - AI for Cyber Security                          TGS-2023039177
--   3. WSQ - AI for Network Security                        TGS-2024051414  <-- NEW
--   4. WSQ - AI Agent Cybersecurity                         TGS-2025053228
--   5. WSQ - AI Security Governance for Businesses          TGS-2026061329
--   6. WSQ - Fundamentals of AI Ethics and Responsible AI   TGS-2023021102
--   7. WSQ - Security Operations for Autonomous AI Agents   TGS-2024042604
--
-- Non-WSQ rows (C434, C1440, C1750) keep their alphabetical slots after the block.
-- The daily category-ordering sweep and 545-style reorders preserve the RELATIVE
-- order of TGS- products, so these pins are durable (only non-WSQ curated pins get
-- flattened). Category 214 has no default_sort_by at any store scope, so it inherits
-- the global catalog/frontend/default_sort_by = 'position' -- the pins take effect.
--
-- Verified against LIVE SG prod 2026-08-29: product TGS-2024051414 (762) has no
-- membership in cat 214 yet, and is enabled (status = 1).
--
-- Category resolved by url_key, products by SKU (business keys; entity ids differ
-- per instance). Both tables written: catalog_category_product (admin) and
-- catalog_category_product_index (what the storefront listing reads; store_id 1 =
-- SG, is_parent 1 = direct assignment) so the listing updates without waiting on a
-- reindex. Partner-safe: TGS- SKUs exist only on SG, so every statement matches
-- zero rows on MY/GH. Idempotent -- re-running rewrites the same absolute positions
-- rather than shifting again.

SET @cat := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'ai-security-series'
  LIMIT 1
);

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024051414' LIMIT 1);

-- 1. add the course to the category (admin table)
INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @e, 3
 WHERE @cat IS NOT NULL AND @e IS NOT NULL
ON DUPLICATE KEY UPDATE position = 3;

-- 2. mirror into the storefront listing index
INSERT INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @e, 3, 1, 1,
       (SELECT i.value FROM catalog_product_entity_int i
         WHERE i.entity_id = @e AND i.store_id = 0
           AND i.attribute_id = (SELECT attribute_id FROM eav_attribute
                                  WHERE entity_type_id = 4 AND attribute_code = 'visibility')
         LIMIT 1)
 WHERE @cat IS NOT NULL AND @e IS NOT NULL
ON DUPLICATE KEY UPDATE position = 3;

-- 3. renumber the rest of the curated WSQ block around the insertion
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2025060473' THEN 0
  WHEN 'TGS-2025060472' THEN 1
  WHEN 'TGS-2023039177' THEN 2
  WHEN 'TGS-2025053228' THEN 4
  WHEN 'TGS-2026061329' THEN 5
  WHEN 'TGS-2023021102' THEN 6
  WHEN 'TGS-2024042604' THEN 7
END
WHERE cp.category_id = @cat
  AND p.sku IN ('TGS-2025060473', 'TGS-2025060472', 'TGS-2023039177',
                'TGS-2025053228', 'TGS-2026061329', 'TGS-2023021102',
                'TGS-2024042604');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2025060473' THEN 0
  WHEN 'TGS-2025060472' THEN 1
  WHEN 'TGS-2023039177' THEN 2
  WHEN 'TGS-2025053228' THEN 4
  WHEN 'TGS-2026061329' THEN 5
  WHEN 'TGS-2023021102' THEN 6
  WHEN 'TGS-2024042604' THEN 7
END
WHERE i.category_id = @cat
  AND p.sku IN ('TGS-2025060473', 'TGS-2025060472', 'TGS-2023039177',
                'TGS-2025053228', 'TGS-2026061329', 'TGS-2023021102',
                'TGS-2024042604');
