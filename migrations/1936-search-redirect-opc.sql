-- 1936: search term "opc" -> CASL Setup One Person Company with Autonomous AI Agents (TGS-2026066850).
-- The auto-matcher had sent "opc" to the catalog fallback page (wsq-funded-courses.html).
-- Exact term only: '%opc%' would also catch unrelated rows such as "python opcv".
-- Applied live on SG 2026-11-15; this keeps a rebuilt DB in the same state. SG only.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-setup-one-person-company-with-autonomous-ai-agents.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) = 'opc';
