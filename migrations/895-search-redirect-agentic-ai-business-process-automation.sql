-- Search-term redirect: "Agentic AI for Business Process Automation" -> the
-- WSQ course product page.
-- The '%agentic ai%business process automation%' pattern covers the "WSQ -"
-- prefix and the no-"for" variant, without touching the sibling
-- "Building Agentic AI Workflows to Automate Business Processes" terms
-- (different wording: "automate business processes").
-- Applied live on SG prod 2026-08-08; this keeps a rebuilt DB in the same state.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-agentic-ai-for-business-process-automation.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @tgt)
  AND LOWER(query_text) LIKE '%agentic ai%business process automation%';
