-- C740 Claude Certified Architect - Professional (CCAR-P) Exam Prep: 4 days / 30 h / $1,400
--    -> 2 days / 15 h / $700 (same shape as its sibling C437 CCAR-F).
--
-- Schedule template D02 -> B07 Tues-Wed/Sat/Sun 2nd wk (keeps the 2nd-week intake; there is no B02,
-- and C740 has no WSQ twin, so the template is the user's choice). The switch is a CODE path
-- (CoursesaveController::switchScheduleTemplateAction, run headlessly on prod) -- NOT done here.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C740' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @a_dur   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');
SET @a_price := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '15' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '2' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_dur, @a_sess) AND store_id <> 0;

INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @pid, 700.0000 FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_decimal
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price AND store_id <> 0;

-- Price index, so listings show the new fee before the next price reindex.
-- (Flat row: refreshed by the post-deploy catalog_product_flat reindex.)
UPDATE catalog_product_index_price
   SET price = 700.0000,
       final_price = IF(final_price > 0, 700.0000, final_price),
       min_price   = IF(min_price   > 0, 700.0000, min_price),
       max_price   = IF(max_price   > 0, 700.0000, max_price)
 WHERE @ok AND entity_id = @pid;
