-- Search "comptia certified a+ training (core 1 and core 2)" (stored with the "+" as a space,
-- single- or double-spaced) and "comptia a=" -> the WSQ CompTIA A+ course page.
-- Exact terms only. NULL-safe overwrite + insert-if-missing. SG only.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-comptia-certified-a-training-core-1-and-core-2.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND REPLACE(LOWER(TRIM(query_text)), '  ', ' ') IN (
    'comptia certified a training (core 1 and core 2)',
    'comptia a='
  );

INSERT INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed, display_in_terms)
SELECT t.term, 1, 1, 1, @tgt, 1, 1
FROM (
  SELECT 'comptia certified a training (core 1 and core 2)' AS term
  UNION ALL SELECT 'comptia certified a  training (core 1 and core 2)'
  UNION ALL SELECT 'comptia a='
) t
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) q
    WHERE LOWER(TRIM(q.query_text)) = t.term
  );
