-- Search-term redirect: "Sustainability Reporting" -> the matching WSQ course page.
--
-- Keep this exact-match only so longer sustainability-reporting searches continue
-- to use their own results or redirects. Create the search term when absent, then
-- populate only missing redirects so existing intentional redirects are preserved.

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
  AND (redirect IS NULL OR TRIM(redirect) = '');
