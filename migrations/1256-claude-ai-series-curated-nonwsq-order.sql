-- 1256: Claude AI Series — curated non-WSQ order (masterclasses first, then certs).
--
-- A) Append 'claude-ai-series' to mmd/category_ordering/curated_url_keys so the
--    nightly CategoryOrdering sweep (01:00 UTC) stops re-alphabetising this
--    category's non-WSQ rows. WITHOUT THIS the pinned order below is flattened
--    back to alphabetical within 24h (see 1199 + the cron's direct
--    core_config_data read). WSQ-first is still enforced by the sweep.
--
-- B) Pin the requested non-WSQ order at positions 101..109 — comfortably after
--    the TGS- block (1..3), which the sweep sorts first regardless.
--      101 Claude Code Masterclass                        (C1417)
--      102 Claude Cowork Masterclass                      (C1382)
--      103 Claude Design Masterclass                      (C201)
--      104 Claude Microsoft 365 Masterclass               (C197)
--      105 Claude Code for Digital Marketing              (C141)
--      106 Claude Certified Associate - Foundations       (C744)
--      107 Claude Certified Architect - Foundations       (C437)
--      108 Claude Certified Architect - Professional      (C364)
--      109 Claude Certified Developer - Foundations       (C439)
--
-- C154 (Claude AI for Digital Marketing) is intentionally omitted — it is
-- disabled (status=2) and carries no index row.
--
-- Positive positions only (negative pins die on reindex — see 1195). Writes
-- BOTH catalog_category_product and catalog_category_product_index (the index
-- is what the storefront actually sorts by; see 545). Business-key lookups, so
-- this is a clean no-op on partner sites that lack the category/SKUs.
-- Idempotent.

SET @claude := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'claude-ai-series' LIMIT 1
);

-- ===== A: curated-order exemption (append, idempotent) =====

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'mmd/category_ordering/curated_url_keys', 'claude-ai-series'
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM (SELECT * FROM core_config_data) c
  WHERE c.path = 'mmd/category_ordering/curated_url_keys'
    AND c.scope = 'default' AND c.scope_id = 0
);

UPDATE core_config_data
SET value = CASE
      WHEN value IS NULL OR value = '' THEN 'claude-ai-series'
      ELSE CONCAT(value, ',claude-ai-series')
    END
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND NOT FIND_IN_SET('claude-ai-series', value);

-- ===== B: pin the curated non-WSQ order (101..109) =====

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C1417' THEN 101
  WHEN 'C1382' THEN 102
  WHEN 'C201'  THEN 103
  WHEN 'C197'  THEN 104
  WHEN 'C141'  THEN 105
  WHEN 'C744'  THEN 106
  WHEN 'C437'  THEN 107
  WHEN 'C364'  THEN 108
  WHEN 'C439'  THEN 109
END
WHERE @claude IS NOT NULL
  AND cp.category_id = @claude
  AND p.sku IN ('C1417','C1382','C201','C197','C141','C437','C364','C744','C439');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C1417' THEN 101
  WHEN 'C1382' THEN 102
  WHEN 'C201'  THEN 103
  WHEN 'C197'  THEN 104
  WHEN 'C141'  THEN 105
  WHEN 'C744'  THEN 106
  WHEN 'C437'  THEN 107
  WHEN 'C364'  THEN 108
  WHEN 'C439'  THEN 109
END
WHERE @claude IS NOT NULL
  AND i.category_id = @claude
  AND p.sku IN ('C1417','C1382','C201','C197','C141','C437','C364','C744','C439');
