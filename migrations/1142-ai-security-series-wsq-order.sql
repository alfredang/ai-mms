-- 1142: Curated WSQ order for the AI Security Series category
--       (/ai-security-series.html), admin-requested 2026-08-27:
--
--   1. WSQ - AI Security for Autonomous AI Agents              TGS-2025060473
--   2. WSQ - AI Security Awareness                             TGS-2025060472
--   3. WSQ - AI for Cyber Security                             TGS-2023039177
--   4. WSQ - AI Agent Cybersecurity                            TGS-2025053228
--   5. WSQ - AI Security Governance for Businesses             TGS-2026061329
--   6. WSQ - Fundamentals of AI Ethics and Responsible AI      TGS-2023021102
--
-- 784/785/786 pattern (same as 1140): the daily category-ordering sweep and
-- 545-style reorders preserve the RELATIVE order of TGS- products, so pinning
-- positions 0..5 here is durable — only non-WSQ curated pins are flattened.
-- Non-WSQ rows (C434, C1440, C1750) keep their alphabetical slots after the
-- WSQ block. SKUs verified against LIVE SG prod index 2026-08-27 (cat 214).
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
    AND v.value = 'ai-security-series'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2025060473' THEN 0
  WHEN 'TGS-2025060472' THEN 1
  WHEN 'TGS-2023039177' THEN 2
  WHEN 'TGS-2025053228' THEN 3
  WHEN 'TGS-2026061329' THEN 4
  WHEN 'TGS-2023021102' THEN 5
END
WHERE cp.category_id = @cat
  AND p.sku IN ('TGS-2025060473', 'TGS-2025060472', 'TGS-2023039177',
                'TGS-2025053228', 'TGS-2026061329', 'TGS-2023021102');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2025060473' THEN 0
  WHEN 'TGS-2025060472' THEN 1
  WHEN 'TGS-2023039177' THEN 2
  WHEN 'TGS-2025053228' THEN 3
  WHEN 'TGS-2026061329' THEN 4
  WHEN 'TGS-2023021102' THEN 5
END
WHERE i.category_id = @cat
  AND p.sku IN ('TGS-2025060473', 'TGS-2025060472', 'TGS-2023039177',
                'TGS-2025053228', 'TGS-2026061329', 'TGS-2023021102');
