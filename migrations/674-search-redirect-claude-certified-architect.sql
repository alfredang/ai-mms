-- 674: search-term redirects "Claude Certified Architect Foundation" ->
-- WSQ - Claude Certified Architect Foundation course (SG).
--
-- WHY: user directive -- searching the course title should land directly on
-- the canonical funded course page instead of a results listing. Prod already
-- has rows 'Claude Certified Architect Foundation' (popularity 2) and
-- 'claude architect' (popularity 1), both redirect NULL.
--
-- WHAT: point these EXACT terms at
-- wsq-claude-certified-architect-foundation.html (HTTP 200 verified on prod
-- 2026-07-22, no redirect chain). INSERT each row if a live search never
-- created it yet, then UPDATE so it works whether or not the row exists.
--
-- SCOPE: explicit term list, not a LIKE sweep. Set unconditionally for these
-- terms (per user directive).
--
-- Partner-safe: SG store-code guard, so MY/GH are a no-op. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-claude-certified-architect-foundation.html';

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT t.term, 1, 1, 0, @tgt, 1
FROM (
  SELECT 'claude certified architect foundation' AS term
  UNION ALL SELECT 'wsq claude certified architect foundation'
  UNION ALL SELECT 'wsq - claude certified architect foundation'
  UNION ALL SELECT 'claude architect'
) t
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM catalogsearch_query q
    WHERE q.store_id = 1 AND LOWER(TRIM(q.query_text)) = t.term
  );

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(TRIM(query_text)) IN (
    'claude certified architect foundation',
    'wsq claude certified architect foundation',
    'wsq - claude certified architect foundation',
    'claude architect'
  );
