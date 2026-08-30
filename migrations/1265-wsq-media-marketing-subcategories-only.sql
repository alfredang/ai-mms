-- 1265: WSQ Media & Marketing Courses (url_key 'wsq-media-marketing-courses')
-- should list ONLY the courses that belong to its six sub-categories, and only
-- WSQ/CASL (TGS-) course codes.
--
-- The category had ~221 DIRECT product assignments — effectively the whole WSQ
-- catalog (Python, CompTIA, Tableau, semiconductor, accounting ...) plus one
-- non-TGS course (C711) — which is why unrelated courses were listed. The six
-- children hold 61 products, all already TGS-, so dropping the direct rows and
-- letting anchor inheritance supply the listing yields exactly the wanted set.
--
-- Category 72 and all six children are is_anchor=1, so children's products
-- surface automatically. Removes direct rows on 72 for anything not in a child;
-- keeps direct rows for products that ARE in a child (harmless, and preserves
-- their position). Also backfills index rows for child products that have none
-- on 72 yet, so the listing is correct without relying on a full reindex
-- (a full reindex re-derives anchor rows and would undo curated positions).
--
-- Business-key lookups; no-ops where the categories are absent on this
-- instance. Idempotent.

SET @mm := (
  SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id
   AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'wsq-media-marketing-courses' LIMIT 1
);

-- Resolve the six children from the tree itself rather than hardcoding ids.
DROP TEMPORARY TABLE IF EXISTS tmp_mm_children;
CREATE TEMPORARY TABLE tmp_mm_children (category_id INT PRIMARY KEY);
INSERT INTO tmp_mm_children (category_id)
SELECT ce.entity_id FROM catalog_category_entity ce
WHERE ce.parent_id = @mm AND @mm IS NOT NULL;

-- Products legitimately reachable through the sub-categories, TGS- only.
DROP TEMPORARY TABLE IF EXISTS tmp_mm_keep;
CREATE TEMPORARY TABLE tmp_mm_keep (product_id INT PRIMARY KEY);
INSERT IGNORE INTO tmp_mm_keep (product_id)
SELECT DISTINCT cp.product_id
FROM catalog_category_product cp
JOIN tmp_mm_children k ON k.category_id = cp.category_id
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
WHERE p.sku LIKE 'TGS-%';

-- Drop the direct assignments that put unrelated / non-TGS courses on the page.
DELETE cp FROM catalog_category_product cp
WHERE cp.category_id = @mm
  AND @mm IS NOT NULL
  AND cp.product_id NOT IN (SELECT product_id FROM tmp_mm_keep);

DELETE i FROM catalog_category_product_index i
WHERE i.category_id = @mm
  AND @mm IS NOT NULL
  AND i.product_id NOT IN (SELECT product_id FROM tmp_mm_keep);

-- Backfill index rows for sub-category products not yet surfaced on the parent,
-- for every store on this instance, carrying over each product's own visibility.
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @mm, k.product_id, 0, 0, s.store_id, MAX(i.visibility)
FROM tmp_mm_keep k
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i
  ON i.product_id = k.product_id AND i.store_id = s.store_id
WHERE @mm IS NOT NULL
GROUP BY k.product_id, s.store_id;

DROP TEMPORARY TABLE IF EXISTS tmp_mm_children;
DROP TEMPORARY TABLE IF EXISTS tmp_mm_keep;
