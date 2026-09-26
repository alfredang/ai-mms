-- 1558: Codex AI Series — curated non-WSQ order.
--
-- A) Append 'codex-ai-series' to mmd/category_ordering/curated_url_keys so the
--    nightly CategoryOrdering sweep stops re-alphabetising this category's
--    non-WSQ rows (without it the pin below reverts within 24h — see 1199/1256).
--    WSQ-first is still enforced by the sweep, so TGS-2023041081 stays on top.
--
-- B) Pin the requested non-WSQ order at 101..104, after the TGS- block:
--      101 Agentic AI Applications with Codex   (C695)
--      102 Codex Masterclass                    (C989)
--      103 Codex for Work Automation            (C427, renamed in 1559)
--      104 Codex for Digital Marketing          (C818, renamed in 1560)
--
-- All four are DIRECT members of the category (no anchor-only rows), so
-- writing both catalog_category_product and its index is enough. Positive
-- positions only (1195). Business-key lookups: a site without the category or
-- SKUs no-ops. Idempotent.

SET @codex := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'codex-ai-series' LIMIT 1
);

-- ===== A: curated-order exemption (append, idempotent) =====

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'mmd/category_ordering/curated_url_keys', 'codex-ai-series'
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM (SELECT * FROM core_config_data) c
  WHERE c.path = 'mmd/category_ordering/curated_url_keys'
    AND c.scope = 'default' AND c.scope_id = 0
);

UPDATE core_config_data
SET value = CASE
      WHEN value IS NULL OR value = '' THEN 'codex-ai-series'
      ELSE CONCAT(value, ',codex-ai-series')
    END
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND NOT FIND_IN_SET('codex-ai-series', value);

-- ===== B: pin the curated non-WSQ order (101..104) =====

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE TRIM(p.sku)
  WHEN 'C695' THEN 101
  WHEN 'C989' THEN 102
  WHEN 'C427' THEN 103
  WHEN 'C818' THEN 104
END
WHERE @codex IS NOT NULL
  AND cp.category_id = @codex
  AND TRIM(p.sku) IN ('C695','C989','C427','C818');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE TRIM(p.sku)
  WHEN 'C695' THEN 101
  WHEN 'C989' THEN 102
  WHEN 'C427' THEN 103
  WHEN 'C818' THEN 104
END
WHERE @codex IS NOT NULL
  AND i.category_id = @codex
  AND TRIM(p.sku) IN ('C695','C989','C427','C818');
