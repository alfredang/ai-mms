-- C840 AI for Product Development: clear the 'microsoft_lp' ATC partner left over from the entity's DP-100
-- Azure Data Scientist life. It rendered the "Authorised Microsoft Learning Partner ... register your
-- certification exam at a Pearson VUE test center" card on a course with no Microsoft exam. The WSQ parent
-- (TGS-2024045799) carries no ATC partner either.
--
-- SG-only (store guard), guarded on the exact stale value -> no-op on MY/GH and on re-run.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C840' LIMIT 1);
SET @a_atc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'atc_partners');

DELETE FROM catalog_product_entity_text
 WHERE @sg = 1 AND entity_id = @pid AND attribute_id = @a_atc AND value = 'microsoft_lp';
