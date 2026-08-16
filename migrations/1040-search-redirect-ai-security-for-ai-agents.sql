-- Search-term redirect: "ai security for ai agents" -> WSQ - AI Security for Autonomous AI Agents
--
-- Scope note: deliberately NOT a broad '%ai security%' match. The generic terms
-- ("ai security", "ai security course", "ai security training", "ai security and
-- governance") intentionally point at the AI Security Series category page and must
-- stay that way. Only terms pairing "ai security" WITH "ai agent" belong on this
-- course, which distinguishes it from the sibling non-WSQ C1440
-- "AI Security and Governance for AI Agents" and the other two live WSQ AI-security
-- courses (TGS-2025060472 Awareness, TGS-2026061329 Governance for Businesses).
--
-- Applied live on SG prod 2026-08-17 before this migration was written.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-security-for-autonomous-ai-agents.html';

-- Seed the canonical terms if a searcher has not created them yet.
INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'ai security for ai agents', 1, 1, 0, @tgt, 1 FROM DUAL
WHERE @sg = 1 AND NOT EXISTS (
  SELECT 1 FROM (SELECT query_id FROM catalogsearch_query
                 WHERE store_id = 1 AND query_text = 'ai security for ai agents') z);

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'ai security for autonomous ai agents', 1, 1, 0, @tgt, 1 FROM DUAL
WHERE @sg = 1 AND NOT EXISTS (
  SELECT 1 FROM (SELECT query_id FROM catalogsearch_query
                 WHERE store_id = 1 AND query_text = 'ai security for autonomous ai agents') z);

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'wsq ai security for autonomous ai agents', 1, 1, 0, @tgt, 1 FROM DUAL
WHERE @sg = 1 AND NOT EXISTS (
  SELECT 1 FROM (SELECT query_id FROM catalogsearch_query
                 WHERE store_id = 1 AND query_text = 'wsq ai security for autonomous ai agents') z);

-- Point every "ai security" + "ai agent" variant (incl. rows created later) at the course.
-- NOT (redirect <=> @tgt) is NULL-safe: a plain `redirect <> @tgt` evaluates to NULL for
-- NULL redirects and silently skips exactly the empty rows this is meant to fill.
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(query_text) LIKE '%ai security%'
  AND LOWER(query_text) LIKE '%ai agent%'
  AND NOT (redirect <=> @tgt);
