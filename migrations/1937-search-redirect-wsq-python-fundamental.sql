-- Search terms containing the full course title "Python Fundamental Course for Beginners"
-- (e.g. "WSQ - Python Fundamental Course for Beginners]" with a stray bracket) were
-- auto-matched to the python-programming category page. Point them at the WSQ course.
-- SG only (TGS- course); applied live on SG prod 2026-11-16. Correction => NULL-safe overwrite.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-python-fundamental-course-for-beginners.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%python fundamental course for beginners%';
