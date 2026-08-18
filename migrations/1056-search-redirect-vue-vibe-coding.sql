-- Search-term redirect: "Develop Full Stack Web Applications with Vue Using Vibe Coding"
-- (and all vue+vibe variants) -> the WSQ AI Vibe Coding for Full Stack Web Applications course.
-- Applied live on SG prod 2026-08-18; this migration keeps the state on a rebuilt DB.
-- SG-only guard; NULL-safe overwrite fills empty rows AND corrects wrong ones.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-full-stack-web-applications.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%vue%'
  AND LOWER(query_text) LIKE '%vibe%';
