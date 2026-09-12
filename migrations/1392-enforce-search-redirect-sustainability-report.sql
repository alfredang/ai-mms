-- Enforce the user-approved destination for the exact Sustainability Report term.
--
-- Production had an existing non-empty stale redirect for this query. The search
-- controller rejected that target and cleared it only after the migration ran, so
-- set the explicitly superseded exact term regardless of its previous value.

SET @sg   := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @term := 'Sustainability Report';
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
