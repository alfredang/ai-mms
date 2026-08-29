-- Arduino category (id 73, url_key arduino-courses-in) listing order. SG only.
--
-- Requested order for the WSQ courses:
--   1. WSQ - Practical Electronics Design with Arduino Microcontroller  TGS-2020506075
--   2. WSQ - AI-Assisted C Programming for Arduino                      TGS-2023039924
--   3. WSQ - Internet of Things (IoT) Fundamental for Beginners         TGS-2020504020
-- then the non-WSQ C-prefix courses alphabetically by name, per the
-- category-ordering convention (WSQ first, then C- alphabetical, then partner).
-- There are no CASL (M-prefix) courses in this category.
--
-- Applied live on SG prod 2026-08-29; this file preserves that state for a
-- rebuilt/restored DB.
--
-- Two things this must get right:
--   (a) the category's default_sort_by is 'position' -- verified on prod, so
--       these pins actually take effect. If that ever changes to name/price the
--       pins go inert.
--   (b) positions MUST be mirrored into catalog_category_product_index, or the
--       storefront keeps serving the old order until a full reindex.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @cat := 73;

DROP TEMPORARY TABLE IF EXISTS tmp_arduino_order;
CREATE TEMPORARY TABLE tmp_arduino_order (
  sku VARCHAR(64) NOT NULL PRIMARY KEY,
  pos INT NOT NULL
);

INSERT INTO tmp_arduino_order (sku, pos) VALUES
  ('TGS-2020506075', 1),  -- WSQ - Practical Electronics Design with Arduino Microcontroller
  ('TGS-2023039924', 2),  -- WSQ - AI-Assisted C Programming for Arduino
  ('TGS-2020504020', 3),  -- WSQ - Internet of Things (IoT) Fundamental for Beginners
  ('C1242',          4),  -- 3 Days Arduino Specialization (currently disabled)
  ('C852',           5),  -- Agentic AI for IoT
  ('C218',           6);  -- Robotics with Arduino

UPDATE catalog_category_product cp
JOIN catalog_product_entity e ON e.entity_id = cp.product_id
JOIN tmp_arduino_order t      ON t.sku = e.sku
SET cp.position = t.pos
WHERE @sg = 1 AND cp.category_id = @cat;

UPDATE catalog_category_product_index ci
JOIN catalog_product_entity e ON e.entity_id = ci.product_id
JOIN tmp_arduino_order t      ON t.sku = e.sku
SET ci.position = t.pos
WHERE @sg = 1 AND ci.category_id = @cat;

DROP TEMPORARY TABLE IF EXISTS tmp_arduino_order;
