-- 1201: Re-apply the canonical category listing order in EVERY category —
-- WSQ/CASL/IBF (TGS- SKU) first with their relative order kept, then non-WSQ
-- (C- SKU) alphabetically by course name, then partner/other (M-) last.
--
-- Why now: full reindexes (the nightly mmd_reindex_scheduled cron AND ad-hoc
-- /reindex/api/run calls — two ran 2026-08-30 03:36/03:38 UTC) re-derive
-- ANCHOR-ONLY catalog_category_product_index rows at stale positions
-- (9999/20014/130053-style), stranding courses at the bottom AFTER the 01:00
-- UTC ordering sweep has run. Audit on SG prod found 23 categories with a
-- C-prefix course listed above a TGS- course. The matching code change in
-- MMD_Reindex_Model_Cron::run() now chains the ordering sweep after every
-- full reindex so this stops recurring; this migration repairs the current
-- state on deploy.
--
-- Copy of the canonical 545 renumber (see the category-ordering skill),
-- extended with the SAME curated-category exemption the nightly
-- CategoryOrdering sweep applies (seeded by 1199): categories listed in
-- core_config_data mmd/category_ordering/curated_url_keys keep their existing
-- non-WSQ position order instead of being re-alphabetised (WSQ-first is still
-- enforced). Without this branch, a plain 545 copy would flatten the curated
-- generative-ai-series order that 1199 pinned.
--
-- Partner-safe: no SKU list (TGS-/C/M prefix convention holds on every site;
-- partner sites have no TGS- rows so only the C-alphabetical part acts there);
-- curated config row absent on partners = inert branch. Idempotent.

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
    CROSS JOIN (SELECT @rn := 0, @grp := NULL) init
    ORDER BY
      i.category_id ASC,
      i.store_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
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
    CROSS JOIN (SELECT @rn2 := 0, @cat2 := NULL) init
    ORDER BY
      p.category_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN p.position END ASC,
      CASE WHEN cuk.entity_id IS NOT NULL AND e.sku NOT LIKE 'TGS-%' THEN p.position END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,
      p.product_id ASC
  ) sorted
) ranked ON ranked.category_id = cp.category_id AND ranked.product_id = cp.product_id
SET cp.position = ranked.new_pos;
