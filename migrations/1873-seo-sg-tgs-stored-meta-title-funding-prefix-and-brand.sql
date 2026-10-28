-- SG funded (TGS-) courses: store the meta_title in its rendered form so the Edit Course
-- "Meta Title" field shows the funding and the brand (user directive 2026-10-28):
--   "Funded up to 70% <IBF|CASL|WSQ> <title> | Tertiary Courses Singapore"
-- Scheme from the course's approved badge tags at apply time (IBF > CASL > WSQ, same order as
-- MMD_Seotitle_Block_Html_Head::getFundingPrefixFor), so no hard-coded course list.
-- MMD_Seotitle is idempotent: a title that already starts with the prefix and ends with the brand
-- renders unchanged, so nothing doubles. SG non-WSQ (C-) titles stay bare.
--
-- Peer-safe: only titles that are still bare are touched (not already "Funded…", no baked
-- "Tertiary Courses" brand, no leading WSQ/IBF/CASL word). The one baked SG title
-- (TGS-2024049184 "WSQ DevOps Foundation Training | Tertiary Courses Singapore") is normalised
-- by its exact old value first. All store rows of meta_title are covered.
--
-- SG-only (store guard) -> no-op on MY/GH (they have no TGS- SKUs; their titles are DB-only).
-- Idempotent. Post-deploy: cache flush.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @a_mt := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title' AND backend_type = 'varchar');
SET @ok := (@sg = 1 AND @a_mt IS NOT NULL);

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity e ON e.entity_id = v.entity_id
   SET v.value = 'DevOps Foundation Training'
 WHERE @ok AND v.attribute_id = @a_mt AND TRIM(e.sku) = 'TGS-2024049184'
   AND v.value = 'WSQ DevOps Foundation Training | Tertiary Courses Singapore';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity e ON e.entity_id = v.entity_id
   SET v.value = CONCAT(
         CASE
           WHEN EXISTS (SELECT 1 FROM tag_relation r JOIN tag t ON t.tag_id = r.tag_id
                         WHERE r.product_id = e.entity_id AND t.status = 1 AND t.name = 'IBF') THEN 'Funded up to 70% IBF'
           WHEN EXISTS (SELECT 1 FROM tag_relation r JOIN tag t ON t.tag_id = r.tag_id
                         WHERE r.product_id = e.entity_id AND t.status = 1 AND t.name = 'CASL') THEN 'Funded up to 70% CASL'
           ELSE 'Funded up to 70% WSQ'
         END,
         ' ', TRIM(v.value), ' | Tertiary Courses Singapore')
 WHERE @ok AND v.attribute_id = @a_mt AND TRIM(e.sku) LIKE 'TGS-%'
   AND TRIM(v.value) <> ''
   AND v.value NOT LIKE 'Funded%'
   AND v.value NOT LIKE '%Tertiary Courses%'
   AND v.value NOT REGEXP '^(WSQ|IBF|CASL)[[:space:]-]'
   AND CHAR_LENGTH(v.value) <= 200;
