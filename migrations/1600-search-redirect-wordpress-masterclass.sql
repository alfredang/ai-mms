-- 1600: on-site search "WordPress Masterclass" -> C1067 WordPress Masterclass.
-- No row existed on SG prod, so seed one; any existing / later variant of the
-- title is overwritten (NULL-safe guard). SG-only (store guard).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wordpress-masterclass.html';

INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed)
SELECT 'WordPress Masterclass', 1, 1, @tgt, 1, 1, 1, 1 FROM DUAL
WHERE @sg = 1
  AND NOT EXISTS (SELECT 1 FROM catalogsearch_query
                  WHERE store_id = 1 AND LOWER(TRIM(query_text)) = 'wordpress masterclass');

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%wordpress%masterclass%';
