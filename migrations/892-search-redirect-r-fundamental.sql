-- 892: Point all "r fundamental" search terms at the WSQ R Fundamental
-- and Statistical Analysis for Beginners course page.
--
-- Applied live on SG prod 2026-08-05 (3 stray rows corrected: two pointed
-- at advanced-r-data-analysis-training, one at statistics-fundamental-training).
-- This migration keeps the state on a rebuilt/restored DB and covers rows
-- created later.
--
-- Word-boundary REGEXP, not LIKE: '%r fundamental%' would also match
-- "Scrum Master Fundamentals" and "Python for fundamental", which must
-- keep their own redirects. Correction, so overwrite (not empty-only guard).
-- SG-only via store guard; no-op on partner sites.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-r-fundamental-and-statistical-analysis-for-beginners.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @tgt)
  AND LOWER(query_text) REGEXP '(^|[^a-z0-9])r[[:space:]]+fundamental';
