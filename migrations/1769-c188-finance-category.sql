-- 1769: C188 AI Vibe Coding for Python Financial Analysis — list it on Finance
-- (requested 2026-10-04). Its removal from AI Infrastructure Series shipped in
-- 1766; it is already on AI Vibe Coding Series and Python.
--
-- Finance sits under the anchor Financial Services, so that parent gets an
-- inherited (is_parent = 0) index row too. Membership only; status and
-- visibility untouched. Category by url_key, product by TRIM(sku); no-op where
-- absent. Idempotent.

SET @p := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C188' LIMIT 1);
SET @c := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'finance-courses' LIMIT 1);
SET @parent := (SELECT parent_id FROM catalog_category_entity WHERE entity_id = @c AND level > 2);

-- Direct row after the category's current last position
-- (C- courses list after TGS-; the ordering sweep re-sorts alphabetically).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @c, @p, COALESCE((SELECT MAX(x.position) FROM catalog_category_product x WHERE x.category_id = @c), 0) + 1
FROM DUAL WHERE @p IS NOT NULL AND @c IS NOT NULL;

-- Listing index: the direct row and the anchor parent's inherited row.
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, s.store_id,
  (SELECT MAX(i2.visibility) FROM catalog_category_product_index i2
   WHERE i2.product_id = cp.product_id AND i2.store_id = s.store_id)
FROM catalog_category_product cp
JOIN core_store s ON s.store_id > 0
WHERE cp.category_id = @c AND cp.product_id = @p
  AND EXISTS (SELECT 1 FROM catalog_category_product_index i3
              WHERE i3.product_id = cp.product_id AND i3.store_id = s.store_id);

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @parent, @p, 0, 0, s.store_id,
  (SELECT MAX(i2.visibility) FROM catalog_category_product_index i2
   WHERE i2.product_id = @p AND i2.store_id = s.store_id)
FROM core_store s
WHERE s.store_id > 0 AND @p IS NOT NULL AND @parent IS NOT NULL
  AND EXISTS (SELECT 1 FROM catalog_category_product_index i3
              WHERE i3.product_id = @p AND i3.store_id = s.store_id);
