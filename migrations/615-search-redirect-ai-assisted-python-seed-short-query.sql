-- 615: fixes the no-op seed in 614.
-- 614's guard tested core_store.code = 'sg', but the SG store code is 'singapore',
-- so the short-query INSERT silently did nothing. The three existing long variants
-- were updated correctly by 614 and are left untouched here.
-- Partner-safe: guard matches the SG store by its store code ('singapore'),
-- which is true on the SG instance and on this local SG dataset, but not on MY/GH.

SET @t := 'https://www.tertiarycourses.com.sg/ibf-ai-assisted-python-programming-for-finance.html';

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (
    SELECT 'ai assisted python programming' AS q
    UNION ALL SELECT 'ai assisted python'
) v
WHERE EXISTS (
    SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore'
)
AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) e
    WHERE e.query_text = v.q
);
