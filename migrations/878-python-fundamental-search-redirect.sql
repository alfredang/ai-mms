-- 878: Point "Python Fundamental" search terms at the WSQ Python Fundamental course.
-- Correction: ~50 prod rows redirected to python-3-essential-training-in-singapore.html
-- (a different course), so this OVERWRITES wrong targets rather than filling empties only.
-- Excludes "... and Statistical Analysis ..." terms, which belong to the R course.
-- Applied live on SG prod 2026-08-03; this migration keeps a rebuilt DB in the same state.
-- SG-only: no-op on partner sites (MY/GH) where the WSQ course does not exist.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-python-fundamental-course-for-beginners.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(query_text) LIKE '%python fundament%'
  AND LOWER(query_text) NOT LIKE '%statistical%'
  AND (redirect IS NULL OR redirect <> @tgt);
