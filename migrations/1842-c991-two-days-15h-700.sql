-- C991 Claude Certified Associate - Foundations (CCAO-F) Exam Prep: 4 days / 30 h / $1,400
-- -> 2 days / 15 h / $700 (same shape as its sibling C437 CCAR-F).
-- Schedule template D01 -> B01 (same 1st-week slot, as C437) is a code path, run on prod via
-- CoursesaveController::switchScheduleTemplateAction -- not SQL. No WSQ twin, so the same-day
-- template rule does not apply.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent. Post-deploy: price + flat reindex, flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C991' LIMIT 1);
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

INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @pid, 700.0000 FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- a store-scoped override would shadow the store-0 values
DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_dur, @a_sess) AND store_id <> 0;
DELETE FROM catalog_product_entity_decimal
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price AND store_id <> 0;
