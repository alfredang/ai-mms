-- Point generic "vibe coding" search terms at the AI Vibe Coding Series page.
--
-- Scope is deliberately an explicit term list, NOT a LIKE '%vibe%' pattern:
-- SG prod carries ~75 vibe rows, most of which correctly point at a SPECIFIC
-- course (python vibe coding -> wsq-ai-vibe-coding-with-python, react vibe
-- coding -> the React course, ...). A broad pattern combined with the
-- NULL-safe guard would fill every empty vibe row and clobber those.
-- Only the generic/ambiguous variants belong on the series listing page.
--
-- Correction (not a fill): 'vibe coding' previously pointed at
-- wsq-programming-vibe-coding-courses-tertiary-courses-singapore.html, so the
-- NULL-safe NOT (redirect <=> @tgt) guard is required to overwrite it while
-- also populating the rows that were empty.
-- Applied live on SG prod 2026-08-24 (10 rows changed).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/ai-vibe-coding-series.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND TRIM(LOWER(query_text)) IN (
    'vibe coding',
    'vibe  coding',
    'vibe',
    'vibe code',
    'vibe codig',
    'vibe coding course',
    'vibe coding courses',
    'ai vibe',
    'ai vibe coding',
    'wsq vibe coding',
    'vibe coding for ai'
  );
