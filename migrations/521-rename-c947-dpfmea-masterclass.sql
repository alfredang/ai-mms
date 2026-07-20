-- Rename C947: "Design and Process Failure Mode Effect Analysis (DPFMEA) Course"
--           -> "Design and Process Failure Mode Effect Analysis (DPFMEA) Masterclass"
-- url_key stays design-process-fmea; meta_title is custom SEO copy (unchanged).
-- Idempotent; scoped to SKU C947 (SG non-WSQ) only — no-op on partner DBs without it.

SET @eid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C947');
SET @attr_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

UPDATE catalog_product_entity_varchar
SET value = 'Design and Process Failure Mode Effect Analysis (DPFMEA) Masterclass'
WHERE entity_id = @eid AND attribute_id = @attr_name;
