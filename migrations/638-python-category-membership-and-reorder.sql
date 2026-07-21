-- Ensure all live Python courses are assigned to the "Python" category
-- (url_key python-programming), then re-apply the canonical category ordering.
--
-- Missing members found on SG: C179 (AI Vibe Coding for Python Applications,
-- re-enabled in 637), C193 (AI Vibe Coding for Python Data Analysis) and
-- TGS-2021010365 (WSQ - Create RESTful APIs and Web Apps with Python Flask).
-- The category is resolved by url_key and each product by SKU, so every
-- statement no-ops safely on an instance where either side is absent.

SET @python_cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
  WHERE v.store_id = 0 AND v.value = 'python-programming' LIMIT 1);

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @python_cat, e.entity_id, 0
FROM catalog_product_entity e
WHERE e.sku IN ('C179', 'C193', 'TGS-2021010365') AND @python_cat IS NOT NULL;

-- Re-apply canonical ordering (verbatim copy of 545 / 613, see
-- .claude/skills/category-ordering): WSQ (TGS-) first keeping relative order,
-- then non-WSQ (C-) alphabetical by store-0 name, then M/other last.
-- Shipped as part of this NEW file because an already-applied migration never
-- re-runs on prod (schema_migrations tracks by filename).

SET @a_pname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

-- 1) Renumber the storefront-facing index directly, per category AND per store.
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

-- 2) Renumber the base table (store 0 name key) so the admin view matches.
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
