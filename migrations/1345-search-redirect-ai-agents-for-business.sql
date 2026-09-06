-- Search-term redirect: "ai agents for business" (+ "ai agent for business", "aiagents for business")
--   -> WSQ - AI Agents for Business (product 1347, TGS-2023018987).
-- Applied live on SG prod 2026-09-07; this migration keeps a rebuilt DB in the same state.
-- SG store only; partner sites are a no-op via the store guard.
-- NULL-safe guard fills unset rows AND corrects wrong ones, no-ops when already correct.
-- Pattern is deliberately tight: "business innovation with ai agents" is a different live
-- course (product 1057) and must NOT be swept in.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-agents-for-business.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) REGEXP 'ai ?agents? for business';
