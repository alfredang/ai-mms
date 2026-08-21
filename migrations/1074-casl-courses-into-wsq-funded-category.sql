-- 1074 — Add every CASL course to the "WSQ Funded Courses" listing category.
--
-- The homepage "WSQ, CASL and IBF Funded Courses" rail and the funded-courses
-- category page both read the WSQ Funded Courses category (url_key
-- 'wsq-ibf-skillsfuture-utap-funded-courses', id 292 on SG). CASL courses are
-- funded courses and belong in that listing.
--
-- Audit against live SG prod (2026-08-21): 39 products carry a 'CASL - ' name.
-- 38 of them were already members of the category in BOTH catalog_category_product
-- and catalog_category_product_index. Exactly one was missing from both:
--   TGS-2026064173  CASL - AI Agents with Gemini Spark  (entity 1090)
-- It is enabled (status=1), visible (visibility=4) and assigned to website 1, so
-- there is nothing blocking it from the listing other than the absent membership.
--
-- This migration is written as a set-based backfill rather than a single-SKU pin:
-- it adds ANY CASL-named product that is not yet a member, so it also covers CASL
-- courses added between authoring and deploy, and re-running it is a no-op.
--
-- Partner-safe: the category is resolved by url_key (ids differ per site) and the
-- products by name prefix — MY/GH carry no CASL courses, so the whole file
-- no-ops there. Nothing is ever removed.
--
-- Both tables are written. The storefront listing reads
-- catalog_category_product_index, NOT catalog_category_product, and no PHP
-- reindex runs at deploy — writing only the base table leaves the page unchanged
-- (see feedback_category_swap_needs_index_mirror). The index rows use
-- is_parent = 1 / visibility = 4 / store_id > 0, matching what the real indexer
-- writes for direct (non-anchor) assignments, so a later full reindex does not
-- rewrite them.

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

SET @a_name := (
  SELECT attribute_id FROM eav_attribute
   WHERE entity_type_id = 4 AND attribute_code = 'name' LIMIT 1
);

-- Base membership. Position continues after the current max so the new rows do
-- not collide; the nightly CategoryOrdering sweep renumbers to the canonical
-- WSQ-first rule afterwards.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat,
       e.entity_id,
       COALESCE((SELECT MAX(cp2.position) FROM catalog_category_product cp2
                  WHERE cp2.category_id = @cat), 0) + 1
  FROM catalog_product_entity e
  JOIN catalog_product_entity_varchar nv
    ON nv.entity_id = e.entity_id
   AND nv.store_id = 0
   AND nv.attribute_id = @a_name
 WHERE @cat IS NOT NULL
   AND @a_name IS NOT NULL
   AND nv.value LIKE 'CASL - %'
   AND NOT EXISTS (
        SELECT 1 FROM catalog_category_product cp
         WHERE cp.category_id = @cat AND cp.product_id = e.entity_id);

-- Storefront index mirror — this is what the category page actually reads.
-- Restricted to products that are enabled and assigned to that store's website,
-- so a disabled or off-website course never gets forced into the listing.
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
  JOIN catalog_product_entity_varchar nv
    ON nv.entity_id = e.entity_id
   AND nv.store_id = 0
   AND nv.attribute_id = @a_name
  CROSS JOIN core_store s
  JOIN catalog_product_website pw
    ON pw.product_id = e.entity_id
   AND pw.website_id = s.website_id
  LEFT JOIN catalog_product_entity_int st
    ON st.entity_id = e.entity_id
   AND st.store_id = 0
   AND st.attribute_id = (SELECT attribute_id FROM eav_attribute
                           WHERE entity_type_id = 4 AND attribute_code = 'status' LIMIT 1)
  LEFT JOIN catalog_product_entity_int vis
    ON vis.entity_id = e.entity_id
   AND vis.store_id = 0
   AND vis.attribute_id = (SELECT attribute_id FROM eav_attribute
                            WHERE entity_type_id = 4 AND attribute_code = 'visibility' LIMIT 1)
 WHERE @cat IS NOT NULL
   AND @a_name IS NOT NULL
   AND cp.category_id = @cat
   AND nv.value LIKE 'CASL - %'
   AND s.store_id > 0
   AND COALESCE(st.value, 1) = 1
   AND NOT EXISTS (
        SELECT 1 FROM catalog_category_product_index i
         WHERE i.category_id = @cat
           AND i.product_id = cp.product_id
           AND i.store_id = s.store_id);
