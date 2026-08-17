-- 1051: Pin TGS-2022017589 — WSQ - Linux Configuration and Shell Scripting —
-- as the FIRST course in the Linux category (/linux-courses.html).
--
-- It is already in the WSQ block but sits 3rd, behind the two CompTIA WSQ
-- courses. Because it is TGS- (WSQ group), this is a relative-order move
-- INSIDE the WSQ group — the daily category-ordering sweep
-- (MMD_RoleManager_Model_Cron_CategoryOrdering) sorts TGS- rows by their
-- existing position, so it preserves this pin and renumbers to a dense 1..N.
-- The negative position keeps it ahead of every other course until then.
-- Category/product use business-key lookups. Idempotent.

SET @linux_category := (
  SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a
    ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3
   AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0
    AND v.value = 'linux-courses'
  LIMIT 1
);

UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = -1
WHERE cp.category_id = @linux_category
  AND p.sku = 'TGS-2022017589';

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = -1
WHERE i.category_id = @linux_category
  AND p.sku = 'TGS-2022017589';
