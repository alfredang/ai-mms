-- 966: point M&A / mergers / acquisitions search terms at the WSQ M&A course.
--
-- Applied live on SG prod 2026-08-13 (search redirects are data, not code, so the
-- migration alone does not change an already-populated prod row). This file exists so a
-- rebuilt/restored DB keeps the same state.
--
-- NULL-safe guard: `redirect <> @tgt` evaluates to NULL — not TRUE — for rows where
-- redirect IS NULL, so it silently skips exactly the empty rows a fill is meant to cover.
-- The live run proved this: it reported "rows updated: 0" with both empty rows untouched.
-- `NOT (redirect <=> @tgt)` is the correct comparison and doubles as the idempotency guard
-- (rows already on target are excluded, so re-runs are no-ops).
--
-- Matches by LIKE pattern rather than a frozen exact-term list so typo variants
-- ("acquistion") and rows created by future searchers are covered too. Note `&` is a
-- literal in SQL LIKE, so '%m&a%' matches only the literal "M&A" text.
--
-- WSQ/TGS- courses are SG-only, so the store guard makes this a no-op on MY/GH.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-strategic-mergers-and-acquisitions-valuation-risk-and-integration.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
        LOWER(query_text) LIKE '%m&a%'
     OR LOWER(query_text) LIKE '%merger%'
     OR LOWER(query_text) LIKE '%acquisition%'
     OR LOWER(query_text) LIKE '%acquistion%'
  );
