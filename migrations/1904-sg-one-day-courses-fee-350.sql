-- SG one-day non-WSQ fee standard = $350 (admin 2026-11-06). Live exceptions:
--   * C529 Customer Service Masterclass: store 0 = 350 but a store-1 override = 300
--     shadowed it, so the site sold at $300 (same trap as C6, migration 1597).
--   * C8 Basic Hydroponics: store 0 = 250 (its special price expired in 2019).
-- Also drops the same stale store-1 overrides on the disabled C425, C540, C825
-- (350 -> 300) and C972 (700 -> 600) so they cannot resurface if re-enabled.
-- WSQ/CASL TGS- fees are NOT touched.
-- SG only (@mms_instance): partner prices are in their own currency.
-- Idempotent. The price + flat indexers are reindexed for these SKUs after apply.

UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity e ON e.entity_id = d.entity_id
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.entity_type_id = 4
   SET d.value = 350.0000
 WHERE TRIM(e.sku) IN ('C529', 'C8')
   AND a.attribute_code = 'price'
   AND d.store_id = 0
   AND @mms_instance = 'SG';

DELETE d FROM catalog_product_entity_decimal d
  JOIN catalog_product_entity e ON e.entity_id = d.entity_id
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.entity_type_id = 4
 WHERE TRIM(e.sku) IN ('C529', 'C8', 'C425', 'C540', 'C825', 'C972')
   AND a.attribute_code = 'price'
   AND d.store_id <> 0
   AND @mms_instance = 'SG';
