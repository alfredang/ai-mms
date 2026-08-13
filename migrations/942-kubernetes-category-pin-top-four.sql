-- 942: Pin the first FOUR courses on the Kubernetes category page
-- (/kubernetes-courses.html) to an explicit, curated order:
--
--   1. TGS-2021010366  WSQ - Application Integration with Docker and Kubernetes
--   2. TGS-2025053174  WSQ - Kubernetes and Cloud Native Associate (KCNA) Training
--   3. TGS-2025053212  WSQ - Certified Kubernetes Application Developer (CKAD) Training
--   4. TGS-2025054612  WSQ - Certified Kubernetes Administrator (CKA) Training
--
-- Supersedes the single pin from migration 941 (which only placed TGS-2021010366
-- first). All four are WSQ (TGS-) courses, so the WSQ-before-non-WSQ convention
-- still holds. Everything NOT in the pinned list keeps its existing relative
-- order and is repacked into positions 5..N behind them.
--
-- Partner-safe: TGS- courses are SG-only, so the pinned SKUs resolve to nothing
-- on MY/GH and the repack degenerates to a stable no-op renumber there.
-- Idempotent: re-running recomputes identical positions.

SET @cat := (
    SELECT v.entity_id
    FROM catalog_category_entity_varchar v
    JOIN eav_attribute a
      ON a.attribute_id = v.attribute_id
     AND a.attribute_code = 'url_key'
     AND a.entity_type_id = (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category')
    WHERE v.store_id = 0
      AND v.value = 'kubernetes-courses'
    LIMIT 1
);

-- Rank 1..4 for the pinned SKUs, NULL for everything else.
-- Guarded so a missing/disabled SKU on any instance simply drops out of the pin
-- list instead of aborting.
-- NOTE: plain (non-TEMPORARY) tables on purpose. MySQL cannot reopen a TEMPORARY
-- table twice within a single statement, and the repack below references the pin
-- table more than once (error 1137 "Can't reopen table"). Both are dropped at the end.
DROP TABLE IF EXISTS tmp_k8s_pin;
CREATE TABLE tmp_k8s_pin (
    product_id INT UNSIGNED NOT NULL PRIMARY KEY,
    pin_rank   INT NOT NULL
);

INSERT INTO tmp_k8s_pin (product_id, pin_rank)
SELECT p.entity_id, r.pin_rank
FROM (
    SELECT 'TGS-2021010366' AS sku, 1 AS pin_rank
    UNION ALL SELECT 'TGS-2025053174', 2
    UNION ALL SELECT 'TGS-2025053212', 3
    UNION ALL SELECT 'TGS-2025054612', 4
) r
JOIN catalog_product_entity p ON p.sku = r.sku
JOIN catalog_category_product ccp
  ON ccp.product_id = p.entity_id
 AND ccp.category_id = @cat;

-- Repack: pinned rows take 1..4 by pin_rank; the rest follow from 5 upward,
-- ordered by their CURRENT position so existing relative order is preserved.
DROP TABLE IF EXISTS tmp_k8s_order;
CREATE TABLE tmp_k8s_order (
    product_id   INT UNSIGNED NOT NULL PRIMARY KEY,
    new_position INT NOT NULL
);

-- The pinned four take positions 1..4 by pin_rank.
INSERT INTO tmp_k8s_order (product_id, new_position)
SELECT pin.product_id, pin.pin_rank
FROM tmp_k8s_pin pin
WHERE @cat IS NOT NULL;

-- Snapshot the unpinned rows with their CURRENT positions before renumbering. The
-- rank below must be computed against this frozen copy, not against
-- catalog_category_product itself, whose positions shift mid-statement.
DROP TABLE IF EXISTS tmp_k8s_rest;
CREATE TABLE tmp_k8s_rest (
    product_id   INT UNSIGNED NOT NULL PRIMARY KEY,
    old_position INT NOT NULL,
    KEY idx_old (old_position, product_id)
);

INSERT INTO tmp_k8s_rest (product_id, old_position)
SELECT ccp.product_id, ccp.position
FROM catalog_category_product ccp
LEFT JOIN tmp_k8s_pin pin ON pin.product_id = ccp.product_id
WHERE @cat IS NOT NULL
  AND ccp.category_id = @cat
  AND pin.product_id IS NULL;

-- Number the rest by COUNTING how many unpinned rows sort at or before each one,
-- rather than with a @seq counter: MySQL may evaluate a user variable more than once
-- per row (and across UNION ALL branches), which produced gaps like 5,7,9,12 and made
-- re-runs drift. Rank-by-count over the frozen snapshot is deterministic and yields
-- exactly consecutive positions.
INSERT INTO tmp_k8s_order (product_id, new_position)
SELECT r.product_id,
       (SELECT COALESCE(MAX(pin_rank), 0) FROM tmp_k8s_pin)
       + (
           SELECT COUNT(*)
           FROM tmp_k8s_rest r2
           WHERE r2.old_position < r.old_position
              OR (r2.old_position = r.old_position AND r2.product_id <= r.product_id)
       ) AS new_position
FROM tmp_k8s_rest r
WHERE @cat IS NOT NULL;

UPDATE catalog_category_product ccp
JOIN tmp_k8s_order o ON o.product_id = ccp.product_id
SET ccp.position = o.new_position
WHERE @cat IS NOT NULL
  AND ccp.category_id = @cat;

-- Mirror into the category product index so the storefront listing reflects the
-- new order without waiting for a full reindex
-- (see feedback_category_swap_needs_index_mirror).
UPDATE catalog_category_product_index i
JOIN catalog_category_product ccp
  ON ccp.category_id = i.category_id
 AND ccp.product_id  = i.product_id
SET i.position = ccp.position
WHERE @cat IS NOT NULL
  AND i.category_id = @cat;

DROP TABLE IF EXISTS tmp_k8s_pin;
DROP TABLE IF EXISTS tmp_k8s_rest;
DROP TABLE IF EXISTS tmp_k8s_order;
