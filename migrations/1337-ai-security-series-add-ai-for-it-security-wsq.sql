-- 1337: Add the two "AI for IT Security" WSQ courses to AI Security Series,
-- ahead of the non-WSQ (C-prefix) block.
--
--   TGS-2024048311  WSQ - AI for IT Security
--   TGS-2023039344  WSQ - AI for IT Security Professionals
--
-- Destinations requested:
--   ai-security-series                                  (AI Security Series, 214 on SG)
--   cyber-security-digital-forensic-training-courses    (IT Security, 161 on SG)
--
-- Verified on SG prod 2026-09-05: IT Security (161) ALREADY carries both as
-- direct members inside its WSQ block (positions 6 and 13), so only AI Security
-- Series needs the assignment. The INSERT IGNOREs below cover both categories
-- anyway, so a site where either membership is missing is healed too.
--
-- Placement: AI Security Series is a CURATED category
-- (mmd/category_ordering/curated_url_keys), so no alphabetical re-sort of its
-- C-block. The new rows are inserted at MAX(TGS position)+1 / +2 — i.e. at the
-- tail of the WSQ block — and each destination is then renumbered densely
-- 1..N with the sweep's exact rule (TGS- first keeping relative order, then
-- non-TGS: curated categories keep their existing order, others alphabetical
-- by name, partner/other last). Never MAX(position)+1 across the whole
-- category — that would land a funded course UNDER the C-block (the 1269
-- incident). Positive positions only (negative pins are zeroed by the nightly
-- full reindex).
--
-- The renumber also lifts the three anchor-inherited WSQ rows on IT Security
-- (Navigating Digital Threats, CySA+, AI for IT Networking) that were sitting
-- at stale 20012/20018/30024 positions below the C-block on prod.
--
-- Business-key lookups only (url_key + SKU). Partner-safe: TGS- SKUs do not
-- exist on MY/GH so the inserts are clean no-ops; the renumber applies the
-- same rule the nightly sweep already enforces. Idempotent.

SET @a_pname := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

-- Destination categories ------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_1337_cats;
CREATE TEMPORARY TABLE tmp_1337_cats (category_id INT PRIMARY KEY, is_curated TINYINT NOT NULL DEFAULT 0);
INSERT IGNORE INTO tmp_1337_cats (category_id)
SELECT v.entity_id
FROM catalog_category_entity_varchar v
JOIN eav_attribute a ON a.attribute_id = v.attribute_id
 AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
WHERE v.store_id = 0
  AND v.value IN ('ai-security-series', 'cyber-security-digital-forensic-training-courses');

-- Flag the curated ones so their non-WSQ order is preserved, not re-alphabetised.
UPDATE tmp_1337_cats t
JOIN catalog_category_entity_varchar v ON v.entity_id = t.category_id AND v.store_id = 0
JOIN eav_attribute a ON a.attribute_id = v.attribute_id
 AND a.entity_type_id = 3 AND a.attribute_code = 'url_key'
SET t.is_curated = 1
WHERE FIND_IN_SET(v.value, (
    SELECT value FROM (SELECT value FROM core_config_data
      WHERE path = 'mmd/category_ordering/curated_url_keys'
        AND scope = 'default' AND scope_id = 0 LIMIT 1) cfg
  )) > 0;

-- Courses to add, in the order they should appear ------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_1337_adds;
CREATE TEMPORARY TABLE tmp_1337_adds (sku VARCHAR(64) PRIMARY KEY, seq TINYINT NOT NULL);
INSERT INTO tmp_1337_adds (sku, seq) VALUES
  ('TGS-2024048311', 1),
  ('TGS-2023039344', 2);

-- Tail of each destination's current WSQ block (0 when it has none).
DROP TEMPORARY TABLE IF EXISTS tmp_1337_tgs_max;
CREATE TEMPORARY TABLE tmp_1337_tgs_max (category_id INT PRIMARY KEY, max_pos INT NOT NULL);
INSERT INTO tmp_1337_tgs_max (category_id, max_pos)
SELECT t.category_id, COALESCE(MAX(cp.position), 0)
FROM tmp_1337_cats t
LEFT JOIN (
  catalog_category_product cp
  JOIN catalog_product_entity e ON e.entity_id = cp.product_id AND e.sku LIKE 'TGS-%'
) ON cp.category_id = t.category_id
GROUP BY t.category_id;

-- 1. Direct assignment (no-op where already a member) -------------------------
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT t.category_id, p.entity_id, m.max_pos + a.seq
FROM tmp_1337_cats t
JOIN tmp_1337_tgs_max m ON m.category_id = t.category_id
CROSS JOIN tmp_1337_adds a
JOIN catalog_product_entity p ON p.sku = a.sku;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT t.category_id, p.entity_id, m.max_pos + a.seq, 1, s.store_id, MAX(i.visibility)
FROM tmp_1337_cats t
JOIN tmp_1337_tgs_max m ON m.category_id = t.category_id
CROSS JOIN tmp_1337_adds a
JOIN catalog_product_entity p ON p.sku = a.sku
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
GROUP BY t.category_id, p.entity_id, s.store_id;

-- 2. Renumber each destination densely with the sweep's rule -----------------
-- Index first (covers anchor-inherited rows that have no base row).
UPDATE catalog_category_product_index idx
JOIN (
  SELECT category_id, store_id, product_id,
    (@rn := IF(@grp = CONCAT(category_id, '-', store_id), @rn + 1, 1)) AS new_pos,
    (@grp := CONCAT(category_id, '-', store_id)) AS grp_set
  FROM (
    SELECT i.category_id, i.store_id, i.product_id
    FROM catalog_category_product_index i
    JOIN tmp_1337_cats t ON t.category_id = i.category_id
    JOIN catalog_product_entity e ON e.entity_id = i.product_id
    LEFT JOIN catalog_product_entity_varchar nv
      ON nv.entity_id = e.entity_id AND nv.attribute_id = @a_pname AND nv.store_id = 0
    CROSS JOIN (SELECT @rn := 0, @grp := NULL) init
    ORDER BY
      i.category_id ASC,
      i.store_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN i.position END ASC,                          -- WSQ keep relative order
      CASE WHEN t.is_curated = 1 AND e.sku NOT LIKE 'TGS-%' THEN i.position END ASC, -- curated non-WSQ keep order
      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,                  -- other non-WSQ alphabetical
      i.product_id ASC
  ) sorted
) ranked
  ON ranked.category_id = idx.category_id
 AND ranked.store_id  = idx.store_id
 AND ranked.product_id = idx.product_id
SET idx.position = ranked.new_pos;

-- Base table for the admin view.
UPDATE catalog_category_product cp
JOIN (
  SELECT category_id, product_id,
    (@rn2 := IF(@cat2 = category_id, @rn2 + 1, 1)) AS new_pos,
    (@cat2 := category_id) AS cat_set
  FROM (
    SELECT p.category_id, p.product_id
    FROM catalog_category_product p
    JOIN tmp_1337_cats t ON t.category_id = p.category_id
    JOIN catalog_product_entity e ON e.entity_id = p.product_id
    LEFT JOIN catalog_product_entity_varchar nv
      ON nv.entity_id = e.entity_id AND nv.attribute_id = @a_pname AND nv.store_id = 0
    CROSS JOIN (SELECT @rn2 := 0, @cat2 := NULL) init
    ORDER BY
      p.category_id ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN 0 WHEN e.sku LIKE 'C%' THEN 1 ELSE 2 END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN p.position END ASC,
      CASE WHEN t.is_curated = 1 AND e.sku NOT LIKE 'TGS-%' THEN p.position END ASC,
      CASE WHEN e.sku LIKE 'TGS-%' THEN NULL ELSE nv.value END ASC,
      p.product_id ASC
  ) sorted
) ranked ON ranked.category_id = cp.category_id AND ranked.product_id = cp.product_id
SET cp.position = ranked.new_pos;

DROP TEMPORARY TABLE IF EXISTS tmp_1337_tgs_max;
DROP TEMPORARY TABLE IF EXISTS tmp_1337_adds;
DROP TEMPORARY TABLE IF EXISTS tmp_1337_cats;
