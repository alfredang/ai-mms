-- 1144: point python vibe-coding search terms at the WSQ AI Vibe Coding with Python course
-- Terms covered (either token order): "ai vibe coding for python", "vibe coding python",
-- "python vibe coding", "vibe coding with python", "ai vibe coding with python".
-- Excludes "%python applications%" so the sibling course
-- "Build and Deploy Python Applications with Vibe Coding" keeps its own redirect.
-- Applied live on SG prod 2026-08-28; this keeps a rebuilt DB in the same state.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-with-python.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND ( LOWER(query_text) LIKE '%vibe%coding%python%'
     OR (LOWER(query_text) LIKE '%python%vibe%coding%'
         AND LOWER(query_text) NOT LIKE '%python applications%') );
