-- List the 9 repurposed Microsoft AI certification courses under the
-- "AI Applications Series" category. Resolves the category by NAME (its
-- entity_id differs per site: SG=139, MY=56, GH=56) so it is partner-safe.
-- Idempotent (INSERT IGNORE on the category_id+product_id PK). No-ops on any
-- site missing the category or a SKU. A category-product reindex is required
-- afterwards for the storefront to list them.

SET @cat := (SELECT v.entity_id
  FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='name'
  WHERE v.store_id=0 AND v.value='AI Applications Series' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, e.entity_id, 0
FROM catalog_product_entity e
WHERE e.sku IN ('C711','C864','C926','C1071','C1756','C1759','C1760','C1762','C1768')
  AND @cat IS NOT NULL;
