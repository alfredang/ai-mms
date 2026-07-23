-- 670: TGS-2026061312 follow-up — trainer bio still referenced the old course
-- theme ("optimizing generative AI for real-world deployments"). Point it at
-- the new Claude Certified Architect Foundation positioning.
-- Partner-safe: TGS- SKUs absent on MY/GH => @e NULL => no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2026061312');
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'trainerprofile');

UPDATE catalog_product_entity_text
  SET value = REPLACE(value, 'optimizing generative AI for real-world deployments', 'architecting Claude-powered AI solutions for real-world deployments')
  WHERE entity_id = @e AND attribute_id = @a_tp;
