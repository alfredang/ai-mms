-- 1143: List WSQ - Security Operations for Autonomous AI Agents
--       (TGS-2024042604, repurposed in 1137) on the AI Security Series
--       category (/ai-security-series.html), admin-requested 2026-08-27.
--
-- Pinned at position 6 — the end of the curated WSQ block from 1142
-- (positions 0..5), ahead of the non-WSQ rows (C434, C1440, C1750 at 7+).
-- The nightly category-ordering sweep preserves TGS- relative order, so the
-- pin is durable. Verified against LIVE SG prod 2026-08-27: product 146 has
-- no membership in the category yet.
--
-- Category resolved by url_key; product by SKU (business keys; ids differ per
-- instance). Both tables written: catalog_category_product (admin) and
-- catalog_category_product_index (what the storefront listing reads,
-- store_id 1 = SG, is_parent 1 = direct assignment). Partner-safe: the TGS-
-- SKU exists only on SG, so everything no-ops on MY/GH. Idempotent.

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

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024042604' LIMIT 1);

INSERT INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @e, 6
 WHERE @cat IS NOT NULL AND @e IS NOT NULL
ON DUPLICATE KEY UPDATE position = 6;

INSERT INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @e, 6, 1, 1,
       (SELECT i.value FROM catalog_product_entity_int i
         WHERE i.entity_id = @e AND i.store_id = 0
           AND i.attribute_id = (SELECT attribute_id FROM eav_attribute
                                  WHERE entity_type_id = 4 AND attribute_code = 'visibility')
         LIMIT 1)
 WHERE @cat IS NOT NULL AND @e IS NOT NULL
ON DUPLICATE KEY UPDATE position = 6;
