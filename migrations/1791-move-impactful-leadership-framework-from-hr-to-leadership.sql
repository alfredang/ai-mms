-- 1791: Move TGS-2025054484 "WSQ - Impactful Leadership Framework" off the
-- HR Management listing ('human-resource-management-courses') and onto
-- Leadership ('leadership-training-courses').
--
-- On SG prod (2026-10-06) the course is already a direct member of Leadership
-- (base + index, position 1), so the real change is the removal from
-- HR Management. The Leadership insert is only a safety net for a DB that
-- differs. Both are children of Business & Soft Skills (68); the course keeps
-- its direct row there, so the parent listing is unaffected. It has no child
-- category under HR Management, so the delete is not undone by anchor
-- inheritance on reindex. Business-key lookups; no-ops on sites without this
-- SKU or category. Idempotent.

SET @hr  := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='human-resource-management-courses' LIMIT 1);
SET @ld  := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='leadership-training-courses' LIMIT 1);
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku)='TGS-2025054484' LIMIT 1);

DELETE FROM catalog_category_product WHERE category_id=@hr AND product_id=@pid;
DELETE FROM catalog_category_product_index WHERE category_id=@hr AND product_id=@pid;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @ld, @pid, 1 FROM DUAL WHERE @ld IS NOT NULL AND @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @ld, @pid, 1, 1, s.store_id, COALESCE(vis.value, 4)
FROM core_store s
LEFT JOIN catalog_product_entity_int vis ON vis.entity_id=@pid AND vis.store_id=0
  AND vis.attribute_id=(SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='visibility')
WHERE s.store_id > 0 AND @ld IS NOT NULL AND @pid IS NOT NULL;
