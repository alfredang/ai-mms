-- Point "agentic AI ... HR" on-site search terms at the WSQ Agentic AI for HR course.
--
-- Scope note: the LIKE pattern is deliberately '%agentic%hr%' and NOT '%ai%hr%'.
-- Terms like "AI for HR" / "GenAI for HR" / "Generative AI for HR" legitimately
-- point at wsq-digital-transformation-in-hr-leveraging-generative-ai-... and must
-- NOT be swept up here.
--
-- Correction (not a fill): "Agentic AI HR" / "Agentic AI in HR" were pointing at
-- the generic wsq-agentic-ai-automation-with-n8n course, so the guard overwrites
-- a wrong target rather than only filling empties. The IS NULL branch matters --
-- `NULL <> 'x'` is NULL, not TRUE, so a bare `redirect <> @tgt` silently skips
-- every unset row.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-hr.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @tgt)
  AND LOWER(query_text) LIKE '%agentic%hr%';
