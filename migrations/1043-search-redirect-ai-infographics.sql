-- Search-term redirect: "ai infographics" -> CASL Infographics and Data
-- Visualization with PowerPoint (SG only).
--
-- Applied live on SG prod 2026-08-17.
--
-- Why a NEW file when 1036 already carries this exact %infograph% pattern:
-- "ai infographics" (query_id 77911) was created by a real searcher AFTER 1036
-- had already run, so 1036 was in the ledger and never re-ran to catch it.
-- An APPLIED migration never re-runs, and EDITING 1036 would not re-run either
-- (feedback_edited_shared_migrations_never_rerun_on_prod) -- hence a follow-up
-- file that re-asserts the same end state.
--
-- This is the standing shape of search-redirect work: catalogsearch_query rows
-- appear continuously from live traffic, so a pattern migration only covers the
-- rows that existed when it ran.
--
-- NOT (redirect <=> @tgt) is NULL-safe -- a plain `redirect <> @tgt` silently
-- skips rows whose redirect IS NULL, which is exactly the row being fixed.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-infographics-and-data-visualization-with-powerpoint.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%infograph%';

-- Seed the term so a rebuilt DB has the redirect even before anyone searches it.
INSERT IGNORE INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'ai infographics', 1, 1, 1, @tgt, 1 FROM DUAL WHERE @sg = 1;
