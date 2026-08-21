-- 1075 — Ensure every enabled TGS- course is a DIRECT member of the
-- "WSQ Funded Courses" listing category (SG 292, url_key
-- 'wsq-ibf-skillsfuture-utap-funded-courses').
--
-- Audit against live SG prod (2026-08-21): 299 enabled TGS- products.
--   * 290 were direct members (catalog_category_product).
--   * 298 appeared in catalog_category_product_index — the extra 8 surface only
--     by ANCHOR INHERITANCE (292 is_anchor=1, and they sit in child categories
--     301 "WSQ IT & Security", 344/348/350 IBF, etc.). Those 8 DO render today,
--     but as anchor rows (is_parent = 0) at stale positions like 40067 / 30255,
--     which sorts them to the bottom of the listing.
--   * Exactly 1 was in NEITHER table and does NOT render at all:
--       TGS-2025052659  IBF - AI Assisted Python Programming for Finance (270)
--     It is enabled, visibility 4, website 1, in-stock per
--     cataloginventory_stock_status, and already a member of 344/348/350 — but
--     none of those is a child of 292, so anchor inheritance never reached it.
--
-- This migration gives all 9 a DIRECT assignment. That fixes the one missing
-- course AND stabilises the other 8: a direct (is_parent = 1) row survives a
-- full reindex, whereas anchor-only rows get re-derived at stale 20xxx/40xxx
-- positions and re-strand at the bottom of the listing (the migration-847
-- lesson — see feedback_full_reindex_scrambles_anchor_only_positions).
--
-- Set-based on the SKU prefix with NOT EXISTS guards, so it also covers any
-- TGS- course added between authoring and deploy and re-runs as a no-op.
-- Disabled products are excluded; nothing is ever removed.
--
-- Partner-safe: category resolved by url_key (ids differ per site); MY/GH carry
-- no TGS- courses, so the whole file no-ops there.
--
-- Both tables are written — the listing reads the index and no reindex runs at
-- deploy (feedback_category_swap_needs_index_mirror).

SET @cat := (
  SELECT uk.entity_id
    FROM catalog_category_entity_varchar uk
    JOIN eav_attribute ea
      ON ea.attribute_id = uk.attribute_id
     AND ea.entity_type_id = 3
     AND ea.attribute_code = 'url_key'
   WHERE uk.store_id = 0
     AND uk.value = 'wsq-ibf-skillsfuture-utap-funded-courses'
   LIMIT 1
);

SET @a_status := (
  SELECT attribute_id FROM eav_attribute
   WHERE entity_type_id = 4 AND attribute_code = 'status' LIMIT 1
);

SET @a_vis := (
  SELECT attribute_id FROM eav_attribute
   WHERE entity_type_id = 4 AND attribute_code = 'visibility' LIMIT 1
);

-- Direct base membership for every enabled TGS- course not already assigned.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat,
       e.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM catalog_category_product cp2
                  WHERE cp2.category_id = @cat), 0) + 1
  FROM catalog_product_entity e
  LEFT JOIN catalog_product_entity_int st
    ON st.entity_id = e.entity_id
   AND st.store_id = 0
   AND st.attribute_id = @a_status
 WHERE @cat IS NOT NULL
   AND e.sku LIKE 'TGS-%'
   AND COALESCE(st.value, 1) = 1
   AND NOT EXISTS (
        SELECT 1 FROM catalog_category_product cp
         WHERE cp.category_id = @cat AND cp.product_id = e.entity_id);

-- Promote existing ANCHOR-inherited index rows (is_parent = 0) to direct rows
-- now that a base assignment exists, and re-seat them at the base position so
-- they stop sorting to the bottom on stale 20xxx/40xxx values.
UPDATE catalog_category_product_index i
  JOIN catalog_category_product cp
    ON cp.category_id = i.category_id
   AND cp.product_id  = i.product_id
  JOIN catalog_product_entity e
    ON e.entity_id = i.product_id
   SET i.is_parent = 1,
       i.position  = cp.position
 WHERE @cat IS NOT NULL
   AND i.category_id = @cat
   AND i.is_parent = 0
   AND e.sku LIKE 'TGS-%';

-- Index mirror for anything still absent — this is what the category page reads.
-- Gated on status + website so a disabled or off-website course is never forced
-- into the listing.
INSERT IGNORE INTO catalog_category_product_index
       (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat,
       cp.product_id,
       cp.position,
       1,
       s.store_id,
       COALESCE(vis.value, 4)
  FROM catalog_category_product cp
  JOIN catalog_product_entity e
    ON e.entity_id = cp.product_id
  CROSS JOIN core_store s
  JOIN catalog_product_website pw
    ON pw.product_id = e.entity_id
   AND pw.website_id = s.website_id
  LEFT JOIN catalog_product_entity_int st
    ON st.entity_id = e.entity_id
   AND st.store_id = 0
   AND st.attribute_id = @a_status
  LEFT JOIN catalog_product_entity_int vis
    ON vis.entity_id = e.entity_id
   AND vis.store_id = 0
   AND vis.attribute_id = @a_vis
 WHERE @cat IS NOT NULL
   AND cp.category_id = @cat
   AND e.sku LIKE 'TGS-%'
   AND s.store_id > 0
   AND COALESCE(st.value, 1) = 1
   AND NOT EXISTS (
        SELECT 1 FROM catalog_category_product_index i
         WHERE i.category_id = @cat
           AND i.product_id = cp.product_id
           AND i.store_id = s.store_id);
