-- AI Vibe Coding Series (category 414) — curated ordering + move the video
-- course out to the Agentic AI Series (category 189).
--
-- This is a CURATED pin requested by the user, so it deliberately departs from
-- the category-ordering skill's "WSQ first, then non-WSQ alphabetical" rule:
-- the 20 WSQ/CASL/IBF courses take positions 1-20 in an explicit business
-- order (NOT alphabetical). The non-WSQ C-prefix courses all stay in the
-- category and follow at positions 100+, alphabetical by name.
--
-- Positions are mirrored into catalog_category_product_index because the
-- storefront listing reads the INDEX table, not catalog_category_product
-- (memory feedback_category_swap_needs_index_mirror). Without the mirror the
-- reordering is invisible until a full reindex.
--
-- SG-only guard: partner sites (MY/GH) have no TGS-/CASL WSQ catalog, so the
-- @sg guard makes this a no-op there.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

-- ---------------------------------------------------------------------------
-- 1. Curated positions 1-20 for the WSQ / CASL / IBF courses.
-- ---------------------------------------------------------------------------
CREATE TEMPORARY TABLE tmp_vibe_order (
  product_id INT NOT NULL PRIMARY KEY,
  pos        INT NOT NULL
);

INSERT INTO tmp_vibe_order (product_id, pos) VALUES
  (585,  1),   -- WSQ - Build Professional Web Apps Quickly with AI-Assisted Vibe Coding
  (1083, 2),   -- CASL - Vibe Coding for Basic Web Design
  (1039, 3),   -- WSQ - AI Vibe Coding for Multi Agents System
  (1134, 4),   -- WSQ - AI Vibe Coding for iOS Mobile Apps Development
  (658,  5),   -- WSQ - AI Vibe Coding for Android Apps Development
  (1114, 6),   -- CASL - Build Full Stack React Web App with Vibe Coding
  (1221, 7),   -- WSQ - AI Vibe Coding for Full Stack Web Applications
  (192,  8),   -- WSQ - Build Modern RESTFUL API Applications with AI Assisted Programming
  (1168, 9),   -- WSQ - Vibe Coding a Full Stack NoSQL Web Apps
  (724,  10),  -- WSQ - AI Vibe Coding for Game Development
  (1015, 11),  -- WSQ - AI Vibe Coding with Python
  (270,  12),  -- IBF - AI Assisted Python Programming for Finance
  (1061, 13),  -- CASL - AI Vibe Coding with PyTorch
  (1017, 14),  -- WSQ - AI Vibe Coding for Deep Learning
  (1103, 15),  -- CASL - Pattern Recognition and Machine Learning with R
  (1215, 16),  -- WSQ - AI Vibe Code of Image Generation
  (1227, 17),  -- WSQ - AI Vibe Coding with C#
  (1460, 18),  -- WSQ - Build ASP.NET Web Apps with Vibe Coding
  (1160, 19),  -- WSQ - AI Vibe Coding for UI/UX
  (1233, 20);  -- WSQ - Develop Blockchain and Web3 App with Vibe Coding

UPDATE catalog_category_product cp
JOIN tmp_vibe_order t ON t.product_id = cp.product_id
SET cp.position = t.pos
WHERE @sg = 1 AND cp.category_id = 414;

-- ---------------------------------------------------------------------------
-- 2. Everything else in the category (the non-WSQ C-prefix courses) keeps its
--    membership and sorts alphabetically by name at positions 100+.
--    Uses a name-ordered ranking so the block is deterministic on any DB.
-- ---------------------------------------------------------------------------
SET @nm := (SELECT attribute_id FROM eav_attribute
            WHERE attribute_code = 'name'
              AND entity_type_id = (SELECT entity_type_id FROM eav_entity_type
                                    WHERE entity_type_code = 'catalog_product'));

CREATE TEMPORARY TABLE tmp_vibe_tail (
  product_id INT NOT NULL PRIMARY KEY,
  pos        INT NOT NULL
);

-- Materialise the name-sorted list FIRST, then number it in a second pass.
-- Assigning @rk inside a derived table is unreliable: MySQL does not guarantee
-- the variable increments in the subquery's ORDER BY sequence.
CREATE TEMPORARY TABLE tmp_vibe_tail_src (
  seq        INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL
) ENGINE=MEMORY;

INSERT INTO tmp_vibe_tail_src (product_id)
SELECT cp.product_id
FROM catalog_category_product cp
JOIN catalog_product_entity p ON p.entity_id = cp.product_id
LEFT JOIN catalog_product_entity_varchar v
       ON v.entity_id = p.entity_id AND v.store_id = 0 AND v.attribute_id = @nm
WHERE cp.category_id = 414
  AND cp.product_id NOT IN (SELECT product_id FROM tmp_vibe_order)
  AND cp.product_id <> 1430
ORDER BY v.value, p.sku;

INSERT INTO tmp_vibe_tail (product_id, pos)
SELECT product_id, seq + 99 FROM tmp_vibe_tail_src;

UPDATE catalog_category_product cp
JOIN tmp_vibe_tail t ON t.product_id = cp.product_id
SET cp.position = t.pos
WHERE @sg = 1 AND cp.category_id = 414;

-- ---------------------------------------------------------------------------
-- 3. Move "WSQ - Agentic AI for Video Creation" (1430, TGS-2023036088) out of
--    the Vibe Coding Series and into the Agentic AI Series (189).
-- ---------------------------------------------------------------------------
SET @pos189 := COALESCE((SELECT MAX(position) FROM catalog_category_product
                         WHERE category_id = 189), 0) + 1;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT 189, 1430, @pos189
WHERE @sg = 1
  AND EXISTS (SELECT 1 FROM catalog_product_entity WHERE entity_id = 1430 AND sku = 'TGS-2023036088');

SET @in189 := (SELECT COUNT(*) FROM catalog_category_product
               WHERE category_id = 189 AND product_id = 1430);

DELETE FROM catalog_category_product
WHERE @sg = 1 AND @in189 = 1 AND category_id = 414 AND product_id = 1430;

-- ---------------------------------------------------------------------------
-- 4. Mirror positions into the index table the storefront actually reads,
--    and drop / add the moved product's index rows for both categories.
-- ---------------------------------------------------------------------------
-- 4a. Seed the moved product's index rows for category 189 FIRST (they are
--     copied from its existing 414 index rows), then remove the 414 rows.
INSERT IGNORE INTO catalog_category_product_index
  (category_id, product_id, position, is_parent, store_id, visibility)
SELECT 189, i.product_id, @pos189, 1, i.store_id, i.visibility
FROM catalog_category_product_index i
WHERE @sg = 1 AND i.category_id = 414 AND i.product_id = 1430;

DELETE FROM catalog_category_product_index
WHERE @sg = 1 AND category_id = 414 AND product_id = 1430;

-- 4b. Mirror the curated positions into the index table the storefront reads.
UPDATE catalog_category_product_index i
JOIN catalog_category_product cp
  ON cp.category_id = i.category_id AND cp.product_id = i.product_id
SET i.position = cp.position
WHERE @sg = 1 AND i.category_id IN (189, 414);

DROP TEMPORARY TABLE IF EXISTS tmp_vibe_order;
DROP TEMPORARY TABLE IF EXISTS tmp_vibe_tail;
DROP TEMPORARY TABLE IF EXISTS tmp_vibe_tail_src;
