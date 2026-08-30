-- 1259: AI Security Series — curated non-WSQ order.
--
-- A) Append 'ai-security-series' to mmd/category_ordering/curated_url_keys so
--    the nightly CategoryOrdering sweep (01:00 UTC) stops re-alphabetising the
--    non-WSQ block. WITHOUT THIS the pins below are flattened back to
--    alphabetical within 24h. WSQ-first is still enforced by the sweep, so the
--    eight TGS- courses stay on top.
--
-- B) Pin the requested non-WSQ order at 101..105, after the TGS- block:
--      101 AI for Cyber Security        (C434)
--      102 AI for Network Security      (C356)
--      103 AI Security and Governance   (C1440)
--      104 AI Agent Security            (C28)
--      105 CompTIA SecAI+ Training      (C1750)  <- not named in the request;
--          pinned LAST rather than left unpinned, so it cannot drift into the
--          middle of the curated block on a later sweep.
--
-- Positive positions only (negative pins die on reindex — see 1195). Writes
-- BOTH catalog_category_product and catalog_category_product_index (the index
-- is what the storefront sorts by; see 545). Business-key lookups -> clean
-- no-op on partner sites lacking the category/SKUs. Idempotent.

SET @cat := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'ai-security-series' LIMIT 1
);

-- ===== A: curated-order exemption (append, idempotent) =====

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'mmd/category_ordering/curated_url_keys', 'ai-security-series'
FROM dual
WHERE NOT EXISTS (
  SELECT 1 FROM (SELECT * FROM core_config_data) c
  WHERE c.path = 'mmd/category_ordering/curated_url_keys'
    AND c.scope = 'default' AND c.scope_id = 0
);

UPDATE core_config_data
SET value = CASE
      WHEN value IS NULL OR value = '' THEN 'ai-security-series'
      ELSE CONCAT(value, ',ai-security-series')
    END
WHERE path = 'mmd/category_ordering/curated_url_keys'
  AND scope = 'default' AND scope_id = 0
  AND NOT FIND_IN_SET('ai-security-series', value);

-- ===== B: pin the curated non-WSQ order (101..105) =====

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'C434'  THEN 101
  WHEN 'C356'  THEN 102
  WHEN 'C1440' THEN 103
  WHEN 'C28'   THEN 104
  WHEN 'C1750' THEN 105
END
WHERE @cat IS NOT NULL
  AND cp.category_id = @cat
  AND p.sku IN ('C434','C356','C1440','C28','C1750');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'C434'  THEN 101
  WHEN 'C356'  THEN 102
  WHEN 'C1440' THEN 103
  WHEN 'C28'   THEN 104
  WHEN 'C1750' THEN 105
END
WHERE @cat IS NOT NULL
  AND i.category_id = @cat
  AND p.sku IN ('C434','C356','C1440','C28','C1750');
