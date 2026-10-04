-- 1768: C711 AB-731 Microsoft Certified AI Transformation Leader — list it on
-- AI Agents Series and Leadership (requested 2026-10-04). Its removal from
-- Cloud Computing and Azure Certification shipped in 1766.
--
-- Leadership sits under the anchor Business & Soft Skills, so that parent gets
-- an inherited (is_parent = 0) index row too. Membership only; status and
-- visibility untouched. Categories by url_key, product by TRIM(sku); no-op
-- where absent. Idempotent.

SET @p := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C711' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS tmp_1768_cat;
CREATE TEMPORARY TABLE tmp_1768_cat AS
SELECT v.entity_id AS category_id
FROM catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id
  AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
WHERE v.store_id = 0 AND v.value IN ('ai-agents-series', 'leadership-training-courses');

-- Direct rows, after each category's current last position
-- (C- courses list after TGS-; the ordering sweep re-sorts alphabetically).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT t.category_id, @p,
  COALESCE((SELECT MAX(x.position) FROM catalog_category_product x
            WHERE x.category_id = t.category_id), 0) + 1
FROM tmp_1768_cat t WHERE @p IS NOT NULL;

-- Listing index: the direct rows ...
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT cp.category_id, cp.product_id, cp.position, 1, s.store_id,
  (SELECT MAX(i2.visibility) FROM catalog_category_product_index i2
   WHERE i2.product_id = cp.product_id AND i2.store_id = s.store_id)
FROM tmp_1768_cat t
JOIN catalog_category_product cp ON cp.category_id = t.category_id AND cp.product_id = @p
JOIN core_store s ON s.store_id > 0
WHERE EXISTS (SELECT 1 FROM catalog_category_product_index i3
              WHERE i3.product_id = cp.product_id AND i3.store_id = s.store_id);

-- ... and the anchor parent of Leadership (Business & Soft Skills).
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT c.parent_id, @p, 0, 0, s.store_id,
  (SELECT MAX(i2.visibility) FROM catalog_category_product_index i2
   WHERE i2.product_id = @p AND i2.store_id = s.store_id)
FROM tmp_1768_cat t
JOIN catalog_category_entity c ON c.entity_id = t.category_id AND c.level > 2
JOIN core_store s ON s.store_id > 0
WHERE @p IS NOT NULL
  AND EXISTS (SELECT 1 FROM catalog_category_product_index i3
              WHERE i3.product_id = @p AND i3.store_id = s.store_id);

DROP TEMPORARY TABLE IF EXISTS tmp_1768_cat;
