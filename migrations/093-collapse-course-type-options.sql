-- Collapse the "Course Type" attribute (code: software, attribute_id 194)
-- down to two options: Funded and Non-funded.
--
-- Before: IBF (134), WSQ (138), SkillsFuture (154), Non-funded (198)
-- After:  Funded (new), Non-funded (198)
--
-- All product values that point to IBF/WSQ/SkillsFuture are remapped to the
-- new Funded option, then the old options are removed.

-- 1. Create the new Funded option.
INSERT INTO eav_attribute_option (attribute_id, sort_order) VALUES (194, 1);
SET @funded_oid := LAST_INSERT_ID();

INSERT INTO eav_attribute_option_value (option_id, store_id, value)
VALUES (@funded_oid, 0, 'Funded');

-- 2. Remap every product whose Course Type points to a "funded" subtype
--    onto the new Funded option.
UPDATE catalog_product_entity_int
   SET value = @funded_oid
 WHERE attribute_id = 194
   AND value IN (134, 138, 154);

-- 3. Delete the old subtype option values and options.
DELETE FROM eav_attribute_option_value WHERE option_id IN (134, 138, 154);
DELETE FROM eav_attribute_option       WHERE option_id IN (134, 138, 154);
