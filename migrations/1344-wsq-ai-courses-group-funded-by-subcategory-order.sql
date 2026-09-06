-- 1344: WSQ AI Courses (url_key 'wsq-ai-courses', 325 on SG) — list the funded
-- (WSQ / CASL, all TGS-) courses grouped by SUB-CATEGORY, in the same order the
-- sub-categories appear on the page:
--   1 WSQ Generative AI Courses      (wsq-generative-ai-courses)
--   2 WSQ Agentic AI Courses         (wsq-agentic-ai-courses)
--   3 WSQ AI Agents Courses          (wsq-ai-agents-courses)
--   4 WSQ Multi AI Agents Courses    (wsq-multi-ai-agents-courses)
--   5 WSQ AI Applications Courses    (wsq-ai-applications-courses)
--   6 WSQ AI Vibe Coding Courses     (wsq-ai-vibe-coding-courses)
--   7 WSQ AI Security Courses        (wsq-ai-security-courses)
--
-- Rules (the 1285 grouping rule, applied to this parent only):
--   * Sub-category order = catalog_category_entity.position of the children,
--     which is exactly the sub-category list rendered on the page.
--   * Within a sub-category, that sub-category's own listing order
--     (catalog_category_product_index.position), so per-child pins survive.
--   * A course in SEVERAL sub-categories is placed once, under the FIRST.
--   * A course on the parent but in NO sub-category keeps its relative order
--     at the END (on SG today: Power Apps/Power Automate Workflows, Claude
--     Cowork for Digital Marketing).
--
-- Verified on SG prod 2026-09-07: 101 courses in the parent index, all TGS-.
-- Only 32 carry a DIRECT catalog_category_product row (positions 1..32,
-- interleaved across every sub-category); the other 69 surface only by anchor
-- inheritance, which is why the page opened with a mixed block ahead of the
-- grouped tail. A full reindex re-derives anchor-only positions from the
-- CHILD row, so every course gets a DIRECT row here (847 / 1341 pattern) and
-- the positive 1..N pins (1195 pattern) are then durable through the daily
-- reindex + nightly CategoryOrdering sweep (which keeps TGS relative order).
--
-- The order is derived from the live child tree at apply time — no SKU list —
-- so it is correct on the instance it runs on. Partner-safe: MY/GH have no
-- TGS- courses, so the parent index is empty there and every statement
-- no-ops. Idempotent (re-running recomputes the same 1..N). ASCII only.

SET @a_ukey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @cat := (SELECT entity_id FROM catalog_category_entity_varchar
  WHERE store_id = 0 AND attribute_id = @a_ukey AND value = 'wsq-ai-courses' LIMIT 1);

-- 1. For every course in the parent's index: its FIRST sub-category (by child
--    position, entity_id as tie-break) and its position inside that child.
DROP TEMPORARY TABLE IF EXISTS tmp_1344_rank;
CREATE TEMPORARY TABLE tmp_1344_rank (product_id INT PRIMARY KEY, ckey BIGINT NOT NULL, ipos INT NOT NULL);
INSERT INTO tmp_1344_rank (product_id, ckey, ipos)
SELECT m.product_id, m.ckey, MIN(ci.position)
FROM (
  SELECT i.product_id, MIN(c.position * 1000000 + c.entity_id) AS ckey
  FROM catalog_category_product_index i
  JOIN catalog_category_entity c ON c.parent_id = @cat
  JOIN catalog_category_product_index ci
    ON ci.category_id = c.entity_id AND ci.product_id = i.product_id AND ci.store_id = i.store_id
  WHERE i.category_id = @cat AND @cat IS NOT NULL
  GROUP BY i.product_id
) m
JOIN catalog_category_product_index ci
  ON ci.category_id = MOD(m.ckey, 1000000) AND ci.product_id = m.product_id
GROUP BY m.product_id, m.ckey;

-- 2. Courses on the parent that are in NO sub-category: keep their current
--    relative order, after every grouped course.
DROP TEMPORARY TABLE IF EXISTS tmp_1344_left;
CREATE TEMPORARY TABLE tmp_1344_left (product_id INT PRIMARY KEY, ipos INT NOT NULL);
INSERT INTO tmp_1344_left (product_id, ipos)
SELECT i.product_id, MIN(i.position)
FROM catalog_category_product_index i
WHERE i.category_id = @cat AND @cat IS NOT NULL
  AND i.product_id NOT IN (SELECT product_id FROM tmp_1344_rank)
GROUP BY i.product_id;

-- 3. Dense positive sequence 1..N.
DROP TEMPORARY TABLE IF EXISTS tmp_1344_seq;
CREATE TEMPORARY TABLE tmp_1344_seq (product_id INT PRIMARY KEY, seq INT NOT NULL);
INSERT INTO tmp_1344_seq (product_id, seq)
SELECT product_id, (@rn := @rn + 1)
FROM (
  SELECT u.product_id
  FROM (
    SELECT product_id, ckey, ipos FROM tmp_1344_rank
    UNION ALL
    SELECT product_id, 999999999999 AS ckey, ipos FROM tmp_1344_left
  ) u
  CROSS JOIN (SELECT @rn := 0) init
  ORDER BY u.ckey ASC, u.ipos ASC, u.product_id ASC
) ordered;

-- 4. Direct assignment for every course (anchor-only rows get a base row so
--    the position survives a full reindex).
INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, s.product_id, s.seq
FROM tmp_1344_seq s
WHERE @cat IS NOT NULL;

-- 5. Write the sequence into BOTH tables (every store on this instance).
UPDATE catalog_category_product cp
JOIN tmp_1344_seq s ON s.product_id = cp.product_id
SET cp.position = s.seq
WHERE cp.category_id = @cat AND @cat IS NOT NULL;

UPDATE catalog_category_product_index i
JOIN tmp_1344_seq s ON s.product_id = i.product_id
SET i.position = s.seq
WHERE i.category_id = @cat AND @cat IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_1344_seq;
DROP TEMPORARY TABLE IF EXISTS tmp_1344_left;
DROP TEMPORARY TABLE IF EXISTS tmp_1344_rank;
