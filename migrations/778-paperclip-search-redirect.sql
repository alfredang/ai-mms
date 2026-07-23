-- 778: redirect the "paperclip" search term to the WSQ Manage AI Agents
-- with PaperClip course page (SG).
--
-- WHY: user request 2026-07-23. The two existing 'paperclip' rows pointed at
-- wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html; the dedicated
-- PaperClip course page exists at wsq-manage-ai-agents-with-paperclip.html
-- (verified HTTP 200) and is the correct destination. Intentional overwrite
-- of the previous redirect.
--
-- Already applied directly on SG prod (query_ids 76159, 76162, verified 302);
-- this file is the record so fresh DBs converge.
--
-- Partner-safe: SG store-code guard, so MY/GH are a no-op. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-manage-ai-agents-with-paperclip.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(TRIM(query_text)) = 'paperclip';
