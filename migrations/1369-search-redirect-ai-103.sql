-- Search-term redirect: AI-103 -> Microsoft Certified Azure AI Apps and Agents Developer Associate
--
-- Prod state before this change: the "AI-103" row (query_id 75278, popularity 10)
-- carried a WRONG redirect pointing at ai-for-healthcare.html. An empty-only
-- guard would have skipped it, so this uses the NULL-safe NOT (redirect <=> @tgt)
-- form, which both fills unset rows and overwrites wrong ones.
--
-- Applied live on SG prod 2026-09-08; this file keeps the state on a DB rebuild.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/ai-103-microsoft-certified-azure-ai-apps-and-agents-developer-associate.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
        LOWER(query_text) LIKE '%ai-103%'
     OR LOWER(query_text) LIKE '%ai 103%'
     OR LOWER(query_text) LIKE '%ai103%'
  );
