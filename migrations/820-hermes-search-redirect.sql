-- 820: repoint "hermes" search-term redirects to the Hermes Agent course (SG).
--
-- WHY: 'hermes' and 'hermes agent' currently redirect to
-- wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html — a generic
-- agents course. The catalog now has the exact-match course
-- "WSQ AI Agent with Hermes Agent" at
-- wsq-ai-agent-with-hermes-agent.html (verified HTTP 200 on 2026-07-27).
--
-- SCOPE: explicit exact-term list ('hermes', 'hermes agent'), intentionally
-- OVERWRITING the existing wrong redirect — this is a correction, not a fill.
-- Partner-safe: SG store-code guard, so MY/GH are a no-op. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-agent-with-hermes-agent.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(TRIM(query_text)) IN (
    'hermes',
    'hermes agent'
  );
