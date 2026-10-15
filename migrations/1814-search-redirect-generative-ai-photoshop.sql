-- Search "generative ai with photoshop" (+ close variants of the WSQ Generative AI for Photoshop course)
-- -> the course page. Exact terms only; NULL-safe overwrite + insert-if-missing. SG only.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-photoshop.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) IN ('generative ai with photoshop', 'generative ai for photoshop',
                            'wsq - generative ai for photoshop', 'wsq generative ai for photoshop');

INSERT INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed, display_in_terms)
SELECT t.term, 1, 1, 1, @tgt, 1, 1
FROM (
  SELECT 'generative ai with photoshop' AS term
  UNION ALL SELECT 'generative ai for photoshop'
  UNION ALL SELECT 'wsq generative ai for photoshop'
) t
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) q
    WHERE LOWER(q.query_text) = t.term
  );
