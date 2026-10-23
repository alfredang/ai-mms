-- Follow-up to 1834: the "Claude Certification Exam Prep" category (370) intro still names C437 by
-- its old title ("... and Claude Certified Architect - Foundations Certification."). Swap in the new
-- title, in the EAV text rows and in the category flat table the storefront reads.
--
-- SG-only (store guard). Exact-phrase REPLACE -> idempotent. The flat UPDATE runs through PREPARE
-- so a partner DB without catalog_category_flat_store_1 never parses it ('DO 0' no-op).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @old := 'Claude Certified Architect - Foundations Certification.';
SET @new := 'Claude Certified Architect - Foundations (CCAR-F) Exam Prep.';
SET @a_cdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');
SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
               JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'name'
              WHERE v.store_id = 0 AND v.value = 'Claude Certification Exam Prep' LIMIT 1);

UPDATE catalog_category_entity_text
   SET value = REPLACE(value, @old, @new)
 WHERE @sg = 1 AND entity_id = @cat AND attribute_id = @a_cdesc AND LOCATE(@old, value) > 0;

SET @has_flat := (SELECT COUNT(*) FROM information_schema.tables
                   WHERE table_schema = DATABASE() AND table_name = 'catalog_category_flat_store_1');
SET @q := IF(@sg = 1 AND @has_flat = 1 AND @cat IS NOT NULL,
  CONCAT('UPDATE catalog_category_flat_store_1 SET description = REPLACE(description, ', QUOTE(@old), ', ', QUOTE(@new),
         ') WHERE entity_id = ', @cat, ' AND LOCATE(', QUOTE(@old), ', description) > 0'),
  'DO 0');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
