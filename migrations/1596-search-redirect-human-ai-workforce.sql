-- Search redirect: "Human–AI Workforce" (and title variants) -> WSQ Build a Human-AI
-- Workforce with Autonomous AI Agents. Already applied live on SG prod 2026-09-29.
-- NULL-safe guard fills unset rows and corrects wrong ones; patterns kept tight
-- (human..workforce / "workforce with autonomous") so generic "workforce" terms are untouched.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) LIKE '%human%workforce%'
       OR LOWER(query_text) LIKE '%workforce with autonomous%');
