-- Search redirect + category listing for WSQ AI for IT Networking (TGS-2024052076).
--
-- 1) On-site searches for "ai for it networking" 302 to the course page.
--    NULL-safe guard (NOT (redirect <=> @tgt)) fills empty rows AND corrects
--    wrong ones; tight LIKE so no unrelated term is swept in. SG-only.
-- 2) List the course under Cloud Computing (cloud-computing-courses) and
--    Network Securities (network-securities-courses). Product resolved by SKU,
--    categories by url_key — on MY/GH the TGS- SKU doesn't exist so @pid is
--    NULL and every insert no-ops (partner-safe). Index rows written directly
--    (the storefront reads catalog_category_product_index, and there is no
--    reindex hook at deploy).
-- 3) Canonical 545 renumber (verbatim) so the new WSQ course slots at the end
--    of the WSQ block and positions stay dense. Idempotent.
--
-- Applied live on SG prod 2026-08-29; this file keeps a rebuilt DB consistent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-for-it-networking.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%ai for it networking%';

-- 2) Category membership + index mirror
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024052076' LIMIT 1);
SET @cat_cloud := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
  JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id AND ea.entity_type_id = 3 AND ea.attribute_code = 'url_key'
  WHERE uk.store_id = 0 AND uk.value = 'cloud-computing-courses' LIMIT 1);
SET @cat_netsec := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
  JOIN eav_attribute ea ON ea.attribute_id = uk.attribute_id AND ea.entity_type_id = 3 AND ea.attribute_code = 'url_key'
  WHERE uk.store_id = 0 AND uk.value = 'network-securities-courses' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat_cloud, @pid, 9999 FROM DUAL WHERE @pid IS NOT NULL AND @cat_cloud IS NOT NULL;
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat_netsec, @pid, 9999 FROM DUAL WHERE @pid IS NOT NULL AND @cat_netsec IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat_cloud, @pid, 9999, 1, 1, 4 FROM DUAL WHERE @pid IS NOT NULL AND @cat_cloud IS NOT NULL;
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat_netsec, @pid, 9999, 1, 1, 4 FROM DUAL WHERE @pid IS NOT NULL AND @cat_netsec IS NOT NULL;

-- 3) Canonical ordering renumber (verbatim copy of 545 — WSQ first keeping
--    relative order, non-WSQ alphabetical, M/other last; index then base).

SET @a_pname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

UPDATE catalog_category_product_index idx
JOIN (
  SELECT category_id, store_id, product_id,
    (@rn := IF(@grp = CONCAT(category_id, '-', store_id), @rn + 1, 1)) AS new_pos,
    (@grp := CONCAT(category_id, '-', store_id)) AS grp_set
  FROM (
    SELECT i.category_id, i.store_id, i.product_id
    FROM catalog_category_product_index i
    JOIN catalog_product_entity e ON e.entity_id = i.product_id
    LEFT JOIN catalog_product_entity_varchar nv
      ON nv.entity_id = e.entity_id AND nv.attribute_id = @a_pname AND nv.store_id = 0
    CROSS JOIN (SELECT @rn := 0, @grp := NULL) init
    ORDER BY
      i.category_id ASC,
      i.store_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN i.position END ASC,   -- WSQ keep relative order
      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,  -- non-WSQ alphabetical
      i.product_id ASC
  ) sorted
) ranked
  ON ranked.category_id = idx.category_id
 AND ranked.store_id  = idx.store_id
 AND ranked.product_id = idx.product_id
SET idx.position = ranked.new_pos;

UPDATE catalog_category_product cp
JOIN (
  SELECT category_id, product_id,
    (@rn2 := IF(@cat2 = category_id, @rn2 + 1, 1)) AS new_pos,
    (@cat2 := category_id) AS cat_set
  FROM (
    SELECT p.category_id, p.product_id
    FROM catalog_category_product p
    JOIN catalog_product_entity e ON e.entity_id = p.product_id
    LEFT JOIN catalog_product_entity_varchar nv
      ON nv.entity_id = e.entity_id AND nv.attribute_id = @a_pname AND nv.store_id = 0
    CROSS JOIN (SELECT @rn2 := 0, @cat2 := NULL) init
    ORDER BY
      p.category_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN p.position END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,
      p.product_id ASC
  ) sorted
) ranked ON ranked.category_id = cp.category_id AND ranked.product_id = cp.product_id
SET cp.position = ranked.new_pos;
