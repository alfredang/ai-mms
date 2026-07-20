-- 614: search redirect for "AI Assisted Python Programming for Finance" -> IBF course page
-- SG store only (store_id = 1). Only fills empty redirects; never overwrites an intentional one.
-- Guarded so it is a no-op on partner instances (MY/GH), which have no store_id 1 SG rows.

SET @t := 'https://www.tertiarycourses.com.sg/ibf-ai-assisted-python-programming-for-finance.html';

-- Seed the short natural-language query if it does not exist yet.
INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT 'ai assisted python programming', 1, 0, 0, @t, 1, 1, 0
FROM DUAL
WHERE EXISTS (SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'sg')
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_id FROM catalogsearch_query WHERE store_id = 1 AND query_text = 'ai assisted python programming') x
  );

-- Point the existing variants at the course page.
UPDATE catalogsearch_query
SET redirect = @t
WHERE store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND query_text IN (
    'AI Assisted Python Programming for Finance',
    'AI Assisted Python  Programming for Finance',
    'IBF - AI Assisted Python Programming for Finance',
    'ai assisted python programming'
  );
