-- 331-course-type-by-sku-prefix.sql
--
-- Normalise the storefront "Course Type" layered-nav filter (the `software`
-- product attribute, frontend label "Course Type") to the canonical SG SKU
-- convention:
--     TGS-*  (WSQ)      -> Funded
--     C*     (non-WSQ)  -> Non-funded
--
-- Why: funded WSQ courses were leaking into the "Course Type: Non-funded"
-- filter because ~13 TGS- courses were mis-tagged Non-funded (and 9 left
-- unset), while ~97 C- courses were mis-tagged Funded (and 7 unset). The
-- layered-nav filter itself is stock Magento and correct — this is a data fix.
--
-- Data-only. Idempotent (ON DUPLICATE KEY UPDATE). Partner-safe: every id is
-- resolved by code/label and every write is guarded on those ids being
-- non-NULL, and the SKU-prefix predicates match nothing on M-prefixed partner
-- catalogs — so this no-ops on MY/GH (and no-ops again on SG re-runs).
--
-- NOTE: after this applies, reindex `catalog_product_eav` (layered-nav filter)
-- and `catalog_product_flat` + flush cache so the storefront reflects the new
-- values. The raw EAV write below is the source of truth; the indexes are
-- derived and stale until reindexed.

SET @etype := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product' LIMIT 1);
SET @attr := (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'software' AND entity_type_id = @etype LIMIT 1);
SET @funded := (SELECT o.option_id FROM eav_attribute_option o JOIN eav_attribute_option_value v ON v.option_id = o.option_id AND v.store_id = 0 WHERE o.attribute_id = @attr AND v.value = 'Funded' LIMIT 1);
SET @nonfunded := (SELECT o.option_id FROM eav_attribute_option o JOIN eav_attribute_option_value v ON v.option_id = o.option_id AND v.store_id = 0 WHERE o.attribute_id = @attr AND v.value = 'Non-funded' LIMIT 1);

-- 1) TGS-* (WSQ) -> Funded, at default (store 0) scope.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, e.entity_id, @funded
FROM catalog_product_entity e
WHERE @attr IS NOT NULL AND @funded IS NOT NULL AND @etype IS NOT NULL
  AND e.sku LIKE 'TGS-%'
ON DUPLICATE KEY UPDATE value = @funded;

-- 2) C* (non-WSQ) -> Non-funded, at default (store 0) scope.
INSERT INTO catalog_product_entity_int (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT @etype, @attr, 0, e.entity_id, @nonfunded
FROM catalog_product_entity e
WHERE @attr IS NOT NULL AND @nonfunded IS NOT NULL AND @etype IS NOT NULL
  AND e.sku LIKE 'C%'
ON DUPLICATE KEY UPDATE value = @nonfunded;

-- 3) Drop any store-view overrides for these SKUs so the storefront inherits
--    the corrected default (this removes the store-scoped Non-funded overrides
--    that were pinning WSQ courses into the wrong filter bucket).
DELETE i FROM catalog_product_entity_int i
JOIN catalog_product_entity e ON e.entity_id = i.entity_id
WHERE @attr IS NOT NULL AND i.attribute_id = @attr AND i.store_id <> 0
  AND (e.sku LIKE 'TGS-%' OR e.sku LIKE 'C%');
