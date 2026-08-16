-- Search-term redirect: infographics terms -> CASL Infographics and Data
-- Visualization with PowerPoint (SG only).
--
-- Applied live on SG prod 2026-08-17; this file exists so a rebuilt/restored DB
-- keeps the state. All pre-existing %infograph% rows already pointed at this
-- target; the one that did not was "ai for infographics" (empty redirect,
-- 545 results).
--
-- Guard notes:
--   * NOT (redirect <=> @tgt) is NULL-safe -- a plain `redirect <> @tgt`
--     silently skips rows whose redirect IS NULL (NULL <> 'x' is NULL, not
--     true), which is exactly the row we need to fix.
--   * store_id/code guard makes this a no-op on MY/GH (CASL/WSQ is SG-only).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-infographics-and-data-visualization-with-powerpoint.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%infograph%';
