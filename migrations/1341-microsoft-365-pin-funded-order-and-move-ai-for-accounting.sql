-- 1341: Microsoft 365 (url_key 'microsoft-365-software-training', 23 on SG):
--   (a) pin the WSQ / CASL block in the owner's requested order (1..9), and
--   (b) remove "AI for Accounting" (C104) from the page; keep it in AI for
--       Finance (230) and Accounting (203).
--
-- Requested funded order:
--   1 TGS-2024043856  WSQ  - Enhance Work Productivity with Microsoft 365 Copilot
--   2 TGS-2026064178  CASL - Create Powerpoint Infographics with AI
--   3 TGS-2026064861  CASL - Data Analytics with Excel
--   4 TGS-2021010195  WSQ  - Create Interactive Dashboard Using Excel
--   5 TGS-2020505317  WSQ  - Statistical Data Analysis with Excel for Beginners
--   6 TGS-2021008700  WSQ  - AI Vibe Coding for Excel VBA
--   7 TGS-2026064177  CASL - Excel Power Query and Power Pivot
--   8 TGS-2024049182  WSQ  - Business Transformation with Agentic AI and AI Agents
--   9 TGS-2026064708  CASL - SharePoint Online for End Users
--
-- Verified on SG prod 2026-09-06:
--   * 23 is an ANCHOR category. Only 3 of the 9 funded courses have a direct
--     catalog_category_product row on 23 (positions 1..3); the other 6 surface
--     there ONLY by anchor inheritance from microsoft-excel-trainings (112) and
--     microsoft-powerpoint-training (380). A full reindex re-derives anchor-only
--     index positions from the CHILD's position ((cc.position+1)*(level+1)*10000
--     + cp.position), so index-only pins would not survive the daily 03:00 SGT
--     reindex. The indexer takes MIN(direct position, derived) — so every pinned
--     course gets a DIRECT row here (847 pattern) and the positive 1..9 pins
--     (1195 pattern) are then durable through reindex + nightly sweep (which
--     keeps TGS relative order by index position).
--   * The C-block sits at 10+ and is alphabetical (23 is NOT in the curated
--     allowlist) — untouched.
--   * C104 "AI for Accounting" is on 23 only via anchor inheritance from
--     microsoft-excel-trainings (112, direct row, position 7). Removing it from
--     the whole 23 subtree (= 112) is the only way to drop it off the M365 page.
--     Its grandparent microsoft-software-training (11) holds a DIRECT row for
--     C104 (position 31), so it stays on that page — no parent cleanup branch.
--   * C104 is ALREADY a direct member of ai-for-finance-courses (230, pos 6)
--     and accounting-courses (203, pos 8) — the "add" half is a per-instance
--     safety net only (INSERT IGNORE, tail of the category; the sweep places a
--     C-prefix course correctly within the C-block).
--
-- Business-key lookups only (url_key + SKU). Partner-safe: TGS- SKUs do not
-- exist on MY/GH (pin statements no-op); C104 and the category tree are shared
-- (catalog parity), so the removal + safety-net add apply there too. Idempotent.

SET @a_ukey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @a_ukey AND value = 'microsoft-365-software-training' LIMIT 1);
SET @cat_path := (SELECT path FROM catalog_category_entity WHERE entity_id = @cat);

-- ===== (a) pin the funded block ==============================================

DROP TEMPORARY TABLE IF EXISTS tmp_1341_pins;
CREATE TEMPORARY TABLE tmp_1341_pins (sku VARCHAR(64) PRIMARY KEY, seq TINYINT NOT NULL);
INSERT INTO tmp_1341_pins (sku, seq) VALUES
  ('TGS-2024043856', 1),
  ('TGS-2026064178', 2),
  ('TGS-2026064861', 3),
  ('TGS-2021010195', 4),
  ('TGS-2020505317', 5),
  ('TGS-2021008700', 6),
  ('TGS-2026064177', 7),
  ('TGS-2024049182', 8),
  ('TGS-2026064708', 9);

-- 1. Direct assignment for every pinned course (anchor-only rows get a base
--    row so the position survives a full reindex). Index rows already exist
--    for the anchor-inherited ones; the INSERT IGNORE is a per-instance net.
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, p.entity_id, 9000 + t.seq
FROM tmp_1341_pins t
JOIN catalog_product_entity p ON p.sku = t.sku
WHERE @cat IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, p.entity_id, 9000 + t.seq, 1, s.store_id, MAX(i.visibility)
FROM tmp_1341_pins t
JOIN catalog_product_entity p ON p.sku = t.sku
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = p.entity_id AND i.store_id = s.store_id
WHERE @cat IS NOT NULL
GROUP BY p.entity_id, s.store_id;

-- 2. Shift any unpinned TGS- row out of 1..9 (relative order kept; the sweep
--    re-normalises the tail nightly).
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
SET cp.position = cp.position + 9
WHERE cp.category_id = @cat AND @cat IS NOT NULL
  AND p.sku LIKE 'TGS-%' AND cp.position <= 9
  AND p.sku NOT IN (SELECT sku FROM tmp_1341_pins);

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
SET i.position = i.position + 9
WHERE i.category_id = @cat AND @cat IS NOT NULL
  AND p.sku LIKE 'TGS-%' AND i.position <= 9
  AND p.sku NOT IN (SELECT sku FROM tmp_1341_pins);

-- 3. Pin 1..9 in BOTH tables.
UPDATE catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
JOIN tmp_1341_pins t ON t.sku = p.sku
SET cp.position = t.seq
WHERE cp.category_id = @cat AND @cat IS NOT NULL;

UPDATE catalog_category_product_index i
JOIN catalog_product_entity p ON p.entity_id = i.product_id
JOIN tmp_1341_pins t ON t.sku = p.sku
SET i.position = t.seq
WHERE i.category_id = @cat AND @cat IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_1341_pins;

-- ===== (b) AI for Accounting off the Microsoft 365 page =======================

SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C104' LIMIT 1);

DROP TEMPORARY TABLE IF EXISTS tmp_1341_tree;
CREATE TEMPORARY TABLE tmp_1341_tree (category_id INT PRIMARY KEY);
INSERT IGNORE INTO tmp_1341_tree (category_id)
SELECT entity_id FROM catalog_category_entity
WHERE @cat IS NOT NULL AND (entity_id = @cat OR path LIKE CONCAT(@cat_path, '/%'));

DELETE cp FROM catalog_category_product cp
JOIN tmp_1341_tree t ON t.category_id = cp.category_id
WHERE cp.product_id = @pid AND @pid IS NOT NULL;

DELETE i FROM catalog_category_product_index i
JOIN tmp_1341_tree t ON t.category_id = i.category_id
WHERE i.product_id = @pid AND @pid IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_1341_tree;

-- Safety net: make sure it is in AI for Finance and Accounting (already true
-- on SG). Tail position — it is a C-prefix course, so it belongs in the
-- C-block; the nightly sweep slots it (curated order for 230, alphabetical for
-- 203).
DROP TEMPORARY TABLE IF EXISTS tmp_1341_dst;
CREATE TEMPORARY TABLE tmp_1341_dst (category_id INT PRIMARY KEY, next_pos INT NOT NULL);
INSERT IGNORE INTO tmp_1341_dst (category_id, next_pos)
SELECT v.entity_id,
       (SELECT COALESCE(MAX(position), 0) + 1 FROM catalog_category_product WHERE category_id = v.entity_id)
FROM catalog_category_entity_varchar v
WHERE v.store_id = 0 AND v.attribute_id = @a_ukey
  AND v.value IN ('ai-for-finance-courses', 'accounting-courses');

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT d.category_id, @pid, d.next_pos
FROM tmp_1341_dst d
WHERE @pid IS NOT NULL;

INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT d.category_id, @pid, d.next_pos, 1, s.store_id, MAX(i.visibility)
FROM tmp_1341_dst d
JOIN core_store s ON s.store_id > 0
JOIN catalog_category_product_index i ON i.product_id = @pid AND i.store_id = s.store_id
WHERE @pid IS NOT NULL
GROUP BY d.category_id, s.store_id;

DROP TEMPORARY TABLE IF EXISTS tmp_1341_dst;
