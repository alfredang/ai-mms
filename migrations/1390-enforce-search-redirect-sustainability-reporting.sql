-- Enforce the user-approved destination for the exact Sustainability Reporting term.
--
-- The previous correction accounted for an absolute obsolete redirect, while the
-- production row may store that destination as a relative path. The search phrase
-- itself is exact and explicitly superseded, so update all of its SG duplicates.

SET @sg   := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @term := 'Sustainability Reporting';
SET @tgt  := 'https://www.tertiarycourses.com.sg/wsq-sustainability-reporting-and-gri-standards.html';

INSERT INTO catalogsearch_query
    (query_text, num_results, popularity, redirect, synonym_for, store_id,
     display_in_terms, is_active, is_processed)
SELECT @term, 1, 0, @tgt, NULL, 1, 0, 1, 1
WHERE @sg > 0
  AND NOT EXISTS (
        SELECT 1
        FROM catalogsearch_query
        WHERE store_id = 1
          AND TRIM(LOWER(query_text)) = LOWER(@term)
      );

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_active = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND TRIM(LOWER(query_text)) = LOWER(@term)
  AND NOT (redirect <=> @tgt);
