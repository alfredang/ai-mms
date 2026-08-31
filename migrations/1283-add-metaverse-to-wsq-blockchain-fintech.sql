-- 1283: Add TGS-2023039835 "WSQ - Business Innovation with Metaverse and
-- Immersive Technologies" to WSQ Blockchain & Fintech
-- (url_key 'wsq-blockchain-fintech-courses', cat 322).
--
-- The course is live and enabled but had no membership row for this category.
-- It stays in its existing categories (WSQ Business, Graphics/Immersive, etc) —
-- this is an ADD, not a move.
--
-- The category currently holds one course (TGS-2021009338) and no C-prefix
-- course, so appending at MAX(position)+1 cannot break the funded-first rule
-- here. Mirrors into the storefront index for every store on this instance
-- (the listing reads the index and no reindex runs at deploy), carrying over
-- the product's own visibility. Business-key lookups only; no-ops where the
-- SKU or category is absent on this instance. Idempotent.

SET @bf := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id=v.attribute_id AND a.entity_type_id=3 AND a.attribute_code='url_key'
  WHERE v.store_id=0 AND v.value='wsq-blockchain-fintech-courses' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @bf, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @bf)
FROM catalog_product_entity p
WHERE p.sku = 'TGS-2023039835' AND @bf IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @bf, p.entity_id,
       (SELECT COALESCE(MAX(x.position),0) + 1 FROM catalog_category_product x WHERE x.category_id = @bf),
       1, s.store_id, MAX(i.visibility)
FROM catalog_product_entity p
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE p.sku = 'TGS-2023039835' AND @bf IS NOT NULL
GROUP BY p.entity_id, s.store_id;
