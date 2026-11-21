-- 1951: Category listing order, every category: funded courses that carry the
-- free AI subscription come first (user rule 2026-11-21).
--
-- New order in every category, per store:
--   1. funded (TGS- SKU) courses with the approved "Free AI Subscription"
--      badge tag (WSQ / CASL), relative order kept
--   2. other funded (TGS- SKU) courses, relative order kept
--   3. non-WSQ (C- SKU) courses, alphabetical by course name (curated
--      categories in mmd/category_ordering/curated_url_keys keep their order)
--   4. partner / other (M-) last
--
-- Copy of the 1201 renumber with the extra first tier. The nightly sweep
-- MMD_RoleManager_Model_Cron_CategoryOrdering carries the same expression, so
-- the order holds after every reindex. Writes listing positions only.
--
-- Partner-safe: no SKU list, no row-returning statement; MY/GH have no TGS-
-- rows, so the new tier does nothing there. Idempotent.

SET @a_pname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_caturl := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @curated_keys := REPLACE(IFNULL((SELECT value FROM core_config_data WHERE path = 'mmd/category_ordering/curated_url_keys' ORDER BY scope_id ASC LIMIT 1), ''), ' ', '');

-- 1) Renumber the storefront-facing index directly, per category AND per store
--    (self-contained — covers anchor-inherited rows that have no base row).
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
    LEFT JOIN catalog_category_entity_varchar cuk
      ON cuk.entity_id = i.category_id AND cuk.attribute_id = @a_caturl
     AND cuk.store_id = 0 AND FIND_IN_SET(cuk.value, @curated_keys)
    LEFT JOIN (
      SELECT DISTINCT tr.product_id
      FROM tag_relation tr
      JOIN tag t ON t.tag_id = tr.tag_id
      WHERE t.status = 1 AND t.name = 'Free AI Subscription'
    ) fa ON fa.product_id = e.entity_id
    CROSS JOIN (SELECT @rn := 0, @grp := NULL) init
    ORDER BY
      i.category_id ASC,
      i.store_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' AND fa.product_id IS NOT NULL THEN 0   -- funded + free AI subscription
           WHEN e.sku LIKE 'TGS-%' THEN 1 WHEN e.sku LIKE 'C%' THEN 2 ELSE 3 END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN i.position END ASC,   -- WSQ keep relative order
      CASE WHEN cuk.entity_id IS NOT NULL AND e.sku NOT LIKE 'TGS-%' THEN i.position END ASC,  -- curated non-WSQ keep order
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
    LEFT JOIN catalog_category_entity_varchar cuk
      ON cuk.entity_id = p.category_id AND cuk.attribute_id = @a_caturl
     AND cuk.store_id = 0 AND FIND_IN_SET(cuk.value, @curated_keys)
    LEFT JOIN (
      SELECT DISTINCT tr.product_id
      FROM tag_relation tr
      JOIN tag t ON t.tag_id = tr.tag_id
      WHERE t.status = 1 AND t.name = 'Free AI Subscription'
    ) fa ON fa.product_id = e.entity_id
    CROSS JOIN (SELECT @rn2 := 0, @cat2 := NULL) init
    ORDER BY
      p.category_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' AND fa.product_id IS NOT NULL THEN 0   -- funded + free AI subscription
           WHEN e.sku LIKE 'TGS-%' THEN 1 WHEN e.sku LIKE 'C%' THEN 2 ELSE 3 END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN p.position END ASC,
      CASE WHEN cuk.entity_id IS NOT NULL AND e.sku NOT LIKE 'TGS-%' THEN p.position END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,
      p.product_id ASC
  ) sorted
) ranked ON ranked.category_id = cp.category_id AND ranked.product_id = cp.product_id
SET cp.position = ranked.new_pos;
