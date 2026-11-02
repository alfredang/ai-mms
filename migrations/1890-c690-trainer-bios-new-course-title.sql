-- 1890: C690's per-course trainer bios (trainerprofile, edited on prod 2026-10-17) still name the
-- retired title "AI Agents Fundamentals for Beginners" ("In AI Agents Fundamentals for Beginners,
-- Dr. Ang uses ..."). 1889 renamed the course to "Human-AI Collaboration with Always On AI Agents";
-- retitle the bios to match. Text-only REPLACE on C690's own blob, every scope row.
--
-- SG-only (store guard + TGS- twin must exist) -> no-op on MY/GH. Idempotent: a re-run finds nothing
-- to replace.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C690' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024043854' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, 'AI Agents Fundamentals for Beginners', 'Human-AI Collaboration with Always On AI Agents')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_tp
   AND value LIKE '%AI Agents Fundamentals for Beginners%';
