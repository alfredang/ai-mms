-- 998: point "loop engineering" / "harness engineering" search terms at the WSQ
-- Harness and Loop Engineering for AI Agents course.
--
-- Applied live on SG prod 2026-08-13 (search redirects are data, not code, so the
-- migration alone does not change an already-populated prod row). This file exists so a
-- rebuilt/restored DB keeps the same state.
--
-- NULL-safe guard: `redirect <> @tgt` evaluates to NULL — not TRUE — for rows where
-- redirect IS NULL, so it silently skips exactly the empty rows a fill is meant to cover.
-- The live run proved this again: the first attempt reported "rows updated: 0" while the
-- existing empty "Loop engineering" row stayed untouched. `NOT (redirect <=> @tgt)` is the
-- correct comparison and doubles as the idempotency guard (rows already on target are
-- excluded, so re-runs are no-ops).
--
-- Deliberately scoped to the two-word phrases. The bare "harness" (pop=6) and
-- "communication harness" rows already point at live, correct courses
-- (WSQ Communicate with Confidence / Effective Communication) and are NOT touched —
-- a '%harness%' pattern would have hijacked both.
--
-- The INSERTs seed the two full-title terms that no one has searched yet, so a rebuilt DB
-- has them; the LIKE UPDATE alone cannot create a row that does not exist. Guarded by
-- NOT EXISTS so re-runs are no-ops (catalogsearch_query has no unique key on query_text).
--
-- WSQ/TGS- courses are SG-only, so the store guard makes this a no-op on MY/GH.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-harness-and-loop-engineering-for-ai-agents.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
        LOWER(query_text) LIKE '%loop engineering%'
     OR LOWER(query_text) LIKE '%harness engineering%'
     OR LOWER(query_text) LIKE '%harness and loop%'
  );

INSERT INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed, display_in_terms)
SELECT 'harness engineering', 1, 1, 1, @tgt, 1, 1 FROM DUAL
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT 1 FROM catalogsearch_query
      WHERE store_id = 1 AND query_text = 'harness engineering' LIMIT 1) t
  );

INSERT INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed, display_in_terms)
SELECT 'harness and loop engineering', 1, 1, 1, @tgt, 1, 1 FROM DUAL
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT 1 FROM catalogsearch_query
      WHERE store_id = 1 AND query_text = 'harness and loop engineering' LIMIT 1) t
  );

INSERT INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed, display_in_terms)
SELECT 'harness and loop engineering for ai agents', 1, 1, 1, @tgt, 1, 1 FROM DUAL
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT 1 FROM catalogsearch_query
      WHERE store_id = 1 AND query_text = 'harness and loop engineering for ai agents' LIMIT 1) t
  );
