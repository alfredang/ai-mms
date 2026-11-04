-- 1900: C6's per-course trainer bios (trainerprofile) still name the retired title
-- "AI Powered Wordpress eCommerce" ("In AI Powered Wordpress eCommerce, Dr. Ang shares ...").
-- 1899 renamed the course to "Build a Professional eCommerce Store with Generative AI";
-- retitle the bios to match. Text-only REPLACE on C6's own blob, every scope row.
--
-- SG-only (store guard + TGS- twin must exist) -> no-op on MY/GH. Idempotent: a re-run finds nothing
-- to replace.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C6' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064474' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, 'AI Powered Wordpress eCommerce', 'Build a Professional eCommerce Store with Generative AI')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_tp
   AND value LIKE '%AI Powered Wordpress eCommerce%';
