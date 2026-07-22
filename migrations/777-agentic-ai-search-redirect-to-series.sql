-- 777: repoint the "agentic ai" search term to the Agentic AI Series page (SG).
--
-- WHY: searching "agentic ai" currently redirects to ai-agents-series.html.
-- The dedicated Agentic AI Series landing page exists at
-- agentic-ai-series.html (HTTP 200) and is the correct destination for this
-- generic series-intent query.
--
-- SCOPE: the EXACT term 'agentic ai' only -- course-specific agentic terms
-- (n8n, Langflow, Claude Code, no-code, etc.) already point at their own
-- course pages and are intentionally NOT touched.
--
-- Partner-safe: SG store-code guard, so MY/GH are a no-op. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/agentic-ai-series.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(TRIM(query_text)) = 'agentic ai';
