-- 1597: C6 "AI Powered Wordpress eCommerce" (1-day) -> course fee $350
--
-- PROBED on prod before writing (entity 6):
--   * price store 0 = 350.0000 already, BUT a store-1 (singapore) override row
--     = 300.0000 shadows it -- flat + price index both held 300 and the live page
--     sold at $300. Fix = set store 0 to 350 and drop the store-scope override so
--     the default value applies ("Use Default Value").
--   * no product text attribute or course_C6_* cms_block quotes the old fee.
--
-- SG only (@mms_instance guard): partner C6 prices are in their own currency.
-- Idempotent: re-running writes the same value / deletes nothing.
-- The price + flat indexers must be reindexed after apply.

UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity e ON e.entity_id = d.entity_id
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.entity_type_id = 4
   SET d.value = 350.0000
 WHERE TRIM(e.sku) = 'C6'
   AND a.attribute_code = 'price'
   AND d.store_id = 0
   AND @mms_instance = 'SG';

DELETE d FROM catalog_product_entity_decimal d
  JOIN catalog_product_entity e ON e.entity_id = d.entity_id
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.entity_type_id = 4
 WHERE TRIM(e.sku) = 'C6'
   AND a.attribute_code = 'price'
   AND d.store_id <> 0
   AND @mms_instance = 'SG';
