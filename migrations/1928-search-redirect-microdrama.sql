-- Search redirect: "microdrama" / "micro drama" / "micro-drama"
--   -> CASL - Create Micro Drama with AI (TGS-2026066846), the only drama course.
-- Applied live on SG prod 2026-11-14; this file keeps a rebuilt DB in the same state.
-- SG-only (TGS- course); no-op on partner sites.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-create-micro-drama-with-ai.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND REPLACE(REPLACE(LOWER(query_text), '-', ''), ' ', '') LIKE '%microdrama%';
