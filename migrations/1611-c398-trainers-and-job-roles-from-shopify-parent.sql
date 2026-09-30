-- 1611: C398 "AI for Shopify eCommerce" - Trainers tab + Job Roles from its WSQ parent
--
-- Follow-up to 1594. C398 is a recycled entity: its Trainers tab still listed the
-- data-science trainers of an earlier R-course life (Dwight Nuwan Fonseka,
-- Dr Alvin Ang, Richard Wan) and Job Roles still read "Data analysts / Financial
-- analysts / Marketers / Researchers". The non-WSQ twin is taught from the same
-- courseware as TGS-2026064175 "CASL - AI for Shopify eCommerce Store", so it takes
-- the parent's values:
--   * trainerprofile  - the blob the Trainers tab renders (bios via courses_trainers)
--   * trainers        - the multiselect of trainer ids
--   * whoshouldattend - the Job Roles tab
-- Copied from the parent at store 0 at run time (no literal), then C398's own
-- store-scoped overrides of the three attributes are removed - a store-1
-- trainerprofile override (Dr Alvin Ang) would otherwise keep masking the fix.
--
-- Guarded on the parent existing: partner sites (no TGS- courses) keep their own
-- trainers untouched. Idempotent.

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C398' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064175' LIMIT 1);
SET @pet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT s.entity_type_id, s.attribute_id, 0, @pid, s.value
FROM catalog_product_entity_text s
JOIN eav_attribute a ON a.attribute_id = s.attribute_id AND a.entity_type_id = @pet
WHERE @pid IS NOT NULL AND @src IS NOT NULL
  AND s.entity_id = @src AND s.store_id = 0
  AND a.attribute_code IN ('trainerprofile','trainers','whoshouldattend')
  AND s.value IS NOT NULL AND s.value <> ''
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE t FROM catalog_product_entity_text t
JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.entity_type_id = @pet
WHERE @pid IS NOT NULL AND @src IS NOT NULL
  AND t.entity_id = @pid AND t.store_id <> 0
  AND a.attribute_code IN ('trainerprofile','trainers','whoshouldattend');
