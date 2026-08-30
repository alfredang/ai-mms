-- 1264: List TGS-2020503264 "WSQ - Data Mining and Machine Learning Fundamentals
-- for Beginners" under the WSQ Data Analytics & Data Visualization category
-- (url_key 'wsq-data-analytics-wsq-courses').
--
-- The course is live and enabled but had no membership row for this category,
-- so it never appeared on the listing. Assign it to the category and mirror
-- that into the storefront index (the listing reads the index, and there is no
-- PHP reindex hook at deploy).
--
-- Appended after the existing courses; the category is all-TGS, so the nightly
-- ordering sweep preserves this relative position. Business-key lookups only;
-- no-ops where the SKU or category is absent on this instance. Idempotent.

SET @da_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'wsq-data-analytics-wsq-courses'
  LIMIT 1
);

SET @da_next_pos := (
  SELECT COALESCE(MAX(cp.position), 0) + 1
  FROM catalog_category_product cp
  WHERE cp.category_id = @da_category
);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @da_category, p.entity_id, @da_next_pos
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2020503264'
  AND @da_category IS NOT NULL;

-- Mirror into the storefront index for every store on this instance, carrying
-- over the visibility this product already has there.
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @da_category, p.entity_id, @da_next_pos, 1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s
  ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = p.entity_id
 AND i.store_id = s.store_id
WHERE p.sku = 'TGS-2020503264'
  AND @da_category IS NOT NULL
GROUP BY p.entity_id, s.store_id;
