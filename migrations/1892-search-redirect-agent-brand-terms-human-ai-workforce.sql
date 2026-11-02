-- Search "meta muse", "openai dots", "claude duets", "manus cue", "grok bots" -> the WSQ
-- Build a Human-AI Workforce with Autonomous AI Agents course page.
-- NULL-safe overwrite + insert-if-missing. SG only. (Applied live on SG prod 2026-11-02.)
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) LIKE '%meta muse%'
    OR LOWER(query_text) LIKE '%openai dots%'
    OR LOWER(query_text) LIKE '%claude duets%'
    OR LOWER(query_text) LIKE '%manus cue%'
    OR LOWER(query_text) LIKE '%grok bots%');

INSERT INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed, display_in_terms)
SELECT t.term, 1, 1, 1, @tgt, 1, 1
FROM (SELECT 'meta muse' AS term UNION ALL SELECT 'openai dots' UNION ALL SELECT 'claude duets'
      UNION ALL SELECT 'manus cue' UNION ALL SELECT 'grok bots') t
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) q
    WHERE LOWER(TRIM(q.query_text)) = t.term
  );
