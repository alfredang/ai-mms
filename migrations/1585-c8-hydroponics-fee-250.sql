-- 1585: C8 "Basic Hydroponics Course for Urban Farming" -> course fee $350 -> $250
--
-- PROBED on prod before writing (entity 8, sku 'C8 ' -- note the TRAILING SPACE,
-- hence TRIM(e.sku)):
--   * price 350.0000 -- store 0 row only, no store-scope overrides to chase.
--   * special_price 188.0000 with special_to_date 2019-02-15 -- long expired,
--     inactive, not touched.
--   * no product text attribute or course_C8_* cms_block quotes "350", so only the
--     price row changes.
--
-- SG production only in effect: every statement is keyed by SKU + name, so a
-- partner site whose C8 differs no-ops. Idempotent: re-running writes the same value.
-- The price + flat indexers must be reindexed after apply for the storefront to
-- sell at the new fee.

UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity e ON e.entity_id = d.entity_id
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.entity_type_id = 4
  JOIN catalog_product_entity_varchar n ON n.entity_id = e.entity_id AND n.store_id = 0
  JOIN eav_attribute na ON na.attribute_id = n.attribute_id AND na.entity_type_id = 4 AND na.attribute_code = 'name'
   SET d.value = 250.0000
 WHERE TRIM(e.sku) = 'C8'
   AND n.value = 'Basic Hydroponics Course for Urban Farming'
   AND a.attribute_code = 'price';
