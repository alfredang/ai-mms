-- 662: search-term redirects "vibe coding python" / "python vibe coding" ->
-- WSQ Build and Deploy Python Applications with Vibe Coding (SG).
--
-- WHY: user directive -- both phrasings should land on the funded course that
-- teaches Python vibe coding.
--
-- WHAT: point the two EXACT terms (case/space-insensitive) at
-- wsq-build-and-deploy-python-applications-with-vibe-coding.html (HTTP 200
-- verified on prod). INSERT each row if a live search never created it yet,
-- then UPDATE so it works whether or not the row already exists.
--
-- Applied directly on SG prod (query_id 76144 + 72550) and verified 302 live.
--
-- SCOPE: two explicit terms, not a LIKE sweep. Set unconditionally for those
-- terms (per user directive) rather than empty-guarded.
--
-- Partner-safe: SG store-code guard, so MY/GH are a no-op. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-build-and-deploy-python-applications-with-vibe-coding.html';

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'vibe coding python', 1, 1, 0, @tgt, 1
FROM dual
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM catalogsearch_query
    WHERE store_id = 1 AND LOWER(TRIM(query_text)) = 'vibe coding python'
  );

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'python vibe coding', 1, 1, 0, @tgt, 1
FROM dual
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM catalogsearch_query
    WHERE store_id = 1 AND LOWER(TRIM(query_text)) = 'python vibe coding'
  );

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(TRIM(query_text)) IN ('vibe coding python', 'python vibe coding');
