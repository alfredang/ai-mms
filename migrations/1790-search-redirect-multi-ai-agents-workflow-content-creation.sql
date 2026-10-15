-- Search redirect: 'Multi AI Agents Workflow for Content Creation' (and the
-- truncated 'Multi AI Agents Workflow for Content') -> the course page.
-- Applied live on SG prod 2026-10-06; this keeps a rebuilt DB in sync.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/multi-ai-agents-workflow-for-content-creation.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE 'multi%ai%agents%workflow%for%content%';
