-- Set the AI Vibe Coding series price to $700 (2 days @ $350/day) for C1143,
-- C384, C683 and C138. C1800 is already $700 so it is left as-is. Updates every
-- store-scoped price row for each product (e.g. C384 had a store_id=1 override
-- of $300) so no stale per-store price survives. Idempotent.

SET @price_attr := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='price');

UPDATE catalog_product_entity_decimal d
JOIN catalog_product_entity e ON e.entity_id = d.entity_id
SET d.value = 700.0000
WHERE d.attribute_id = @price_attr AND e.sku IN ('C1143', 'C384', 'C683', 'C138', 'C430');
