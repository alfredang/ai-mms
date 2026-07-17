-- Set the Network Security Masterclass (C1152) price to $700 (2 days @ $350/day).
-- Updates every store-scoped price row for the product so no stale per-store
-- override survives. Idempotent. Guarded implicitly by the SKU join (no-op on
-- sites without C1152).

SET @price_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='price');

UPDATE catalog_product_entity_decimal d
JOIN catalog_product_entity e ON e.entity_id = d.entity_id
SET d.value = 700.0000
WHERE d.attribute_id = @price_attr AND e.sku = 'C1152';
