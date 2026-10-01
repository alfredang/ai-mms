-- C776 AI Transformation with Microsoft Copilot: 1673 copied the WSQ parent's About with
-- "three-day WSQ course" -> "two-day course"; non-WSQ copy must not state a day count (the
-- Duration / Sessions tiles carry it). "a practical two-day course" -> "a practical course".
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent (LIKE guard).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C776' LIMIT 1);
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, 'is a practical two-day course for', 'is a practical course for')
 WHERE @sg = 1 AND entity_id = @pid AND attribute_id = @a_short
   AND value LIKE '%is a practical two-day course for%';
