-- 880: Point "NLP ... beginner/basic" search terms at the WSQ Python Fundamental course.
-- Follow-up to 879, which excluded NLP-with-Python terms. Their old targets
-- (wsq-nlp-deep-learning-python-course.html, wsq-python-text-mining-...) now 301
-- to repurposed AI courses — rotten targets, so this OVERWRITES.
-- Applied live on SG prod 2026-08-03 (14 rows); this migration keeps a rebuilt DB in the same state.
-- SG-only: no-op on partner sites (MY/GH) where the WSQ course does not exist.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-python-fundamental-course-for-beginners.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(query_text) LIKE '%nlp%'
  AND (LOWER(query_text) LIKE '%beginner%' OR LOWER(query_text) LIKE '%basic%')
  AND (redirect IS NULL OR redirect <> @tgt);
