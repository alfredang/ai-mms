-- Search "multi ai agent" / "multi ai agents" -> the Multi-Agents Series category page.
-- Exact terms only (course-title searches containing these words keep their own course
-- redirects). NULL-safe overwrite + insert-if-missing. SG only.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/multi-agents-series.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) IN ('multi ai agent', 'multi ai agents');

INSERT INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed, display_in_terms)
SELECT t.term, 1, 1, 1, @tgt, 1, 1
FROM (
  SELECT 'multi ai agent' AS term
  UNION ALL SELECT 'multi ai agents'
) t
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) q
    WHERE LOWER(TRIM(q.query_text)) = t.term
  );
