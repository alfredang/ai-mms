-- 893: Curate the WSQ course order in the R Programming category
-- (url_key r-programming-courses-in):
--   0  TGS-2019504058  WSQ - R Fundamental and Statistical Analysis for Beginners  (top)
--   1  TGS-2026064475  CASL - Data Analytics and Visualization with R
--   2  TGS-2021010367  WSQ - Text Analytics with R
--   3  TGS-2024049780  WSQ - Bioinformatics Data Analysis with R Bioconductor  (after Text Analytics)
--
-- The daily category-ordering sweep preserves the relative order of TGS-
-- products, so these positions persist. Category and products resolved by
-- business keys; partner sites have no TGS- products so this is a no-op
-- there. Idempotent. Pattern copied from migration 784.

SET @r_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'r-programming-courses-in'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = CASE p.sku
  WHEN 'TGS-2019504058' THEN 0
  WHEN 'TGS-2026064475' THEN 1
  WHEN 'TGS-2021010367' THEN 2
  WHEN 'TGS-2024049780' THEN 3
END
WHERE cp.category_id = @r_category
  AND p.sku IN ('TGS-2019504058', 'TGS-2026064475', 'TGS-2021010367', 'TGS-2024049780');

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = CASE p.sku
  WHEN 'TGS-2019504058' THEN 0
  WHEN 'TGS-2026064475' THEN 1
  WHEN 'TGS-2021010367' THEN 2
  WHEN 'TGS-2024049780' THEN 3
END
WHERE i.category_id = @r_category
  AND p.sku IN ('TGS-2019504058', 'TGS-2026064475', 'TGS-2021010367', 'TGS-2024049780');
