-- 729: Pin "WSQ - Generative AI for SEO" (TGS-2020503501) to the TOP of the
-- SEO category. WSQ rows keep relative order through the canonical reorder,
-- so position 0 + the 730 reorder makes it #1 durably.
-- Category by url_key; TGS- SKU absent on partners => no-op there.

SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE attribute_id = (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key')
    AND store_id = 0 AND value = 'search-engine-optimisation-seo-training-courses' LIMIT 1);
SET @p := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2020503501');

UPDATE catalog_category_product SET position = 0
  WHERE category_id = @cat AND product_id = @p;
UPDATE catalog_category_product_index SET position = 0
  WHERE category_id = @cat AND product_id = @p;
