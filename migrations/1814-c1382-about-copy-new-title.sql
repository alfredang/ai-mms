-- C1382: 1813 renamed the course but its About-sentence REPLACE assumed the local wording
-- ("in this hands-on Claude Cowork Masterclass."). Prod's copy opens "Claude Cowork Masterclass
-- shows you how to ..." so that sentence kept the old title. Fix the prod wording.
-- SG-only (store guard). Idempotent.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1382' LIMIT 1);
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

UPDATE catalog_product_entity_text
   SET value = REPLACE(value, 'Claude Cowork Masterclass shows you how', 'Claude AI Masterclass shows you how')
 WHERE @sg = 1 AND @pid IS NOT NULL AND entity_id = @pid AND attribute_id = @a_sdesc AND store_id = 0;
