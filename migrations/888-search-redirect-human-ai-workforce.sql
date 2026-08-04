-- Search-term redirect: "build a human-ai workforce" (and variants)
--   -> WSQ - Build a Human-AI Workforce with Autonomous AI Agents
--
-- Applied live on SG prod 2026-08-04 (7 rows). This file keeps the state if the
-- DB is rebuilt/restored. WSQ course = SG-only; the store guard makes MY/GH a no-op.
--
-- NULL-safe guard: many prod rows have redirect IS NULL, and `redirect <> @tgt`
-- evaluates to NULL for those (skipping them silently). Use NOT (redirect <=> @tgt).
--
-- LIKE patterns deliberately EXCLUDE the unrelated "Empower Your Workforce with
-- Microsoft 365 Copilot" family, which belongs to a different course.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) LIKE '%human%ai%workforce%'
    OR LOWER(query_text) LIKE '%ai%human%workforce%'
    OR LOWER(query_text) LIKE '%ai workforce%'
    OR LOWER(query_text) LIKE '%workforce with autonomous%');
