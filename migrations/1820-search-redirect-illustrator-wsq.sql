-- Search "illustrator" -> the WSQ Creating Professional Graphics with Adobe Illustrator course
-- (was the Adobe Illustrator courses category page). Exact term only; other Illustrator
-- searches keep their own redirects. NULL-safe overwrite + insert-if-missing. SG only.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-creating-professional-graphics-with-adobe-illustrator.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) = 'illustrator';

INSERT INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed, display_in_terms)
SELECT 'illustrator', 1, 1, 1, @tgt, 1, 1
FROM DUAL
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) q
    WHERE LOWER(TRIM(q.query_text)) = 'illustrator'
  );
