-- 879: Point "python ... beginner" search terms at the WSQ Python Fundamental course.
-- Correction: prod rows redirected these terms to retired course URLs
-- (basic-python-training-for-beginners.html, python-3-essential-training-in-singapore.html)
-- which now 301 to repurposed AI courses — rotten targets, so this OVERWRITES.
-- Excludes NLP-with-Python terms, which belong to a different course.
-- Applied live on SG prod 2026-08-03; this migration keeps a rebuilt DB in the same state.
-- SG-only: no-op on partner sites (MY/GH) where the WSQ course does not exist.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-python-fundamental-course-for-beginners.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(query_text) LIKE '%python%beginner%'
  AND LOWER(query_text) NOT LIKE '%language%'
  AND LOWER(query_text) NOT LIKE '%nlp%'
  AND (redirect IS NULL OR redirect <> @tgt);
