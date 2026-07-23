-- 625: search redirect for "ai applications" / "ai for enterprises" + variants
--      -> AI Applications Series category page.
--
-- Verified: category 139 is named "AI Applications Series" and the live page
-- https://www.tertiarycourses.com.sg/ai-applications-series.html returns HTTP 200
-- with H1 "AI Applications Series".
--
-- SCOPE NOTE 1 -- course titles: almost every existing "%ai application%" query is a
-- LONG exact course title ("Develop Multi-Agent AI Applications with AutoGen",
-- "AI Application Development with Large Language Models", the WSQ- twins, and
-- "Agentic AI Applications with Claude Code" which 622 also excludes). Those name one
-- specific course and stay on normal search results.
--
-- SCOPE NOTE 2 -- the "enterprise" trap: bare 'enterprise'/'enterprises' is NOT
-- redirected. On this catalog those words overwhelmingly belong to ACCOUNTING / SME
-- courses, not AI -- e.g. "WSQ - Xero Accounting System for Small and Medium
-- Enterprises" (313 searches), Quickbooks (291), Budgeting for SMEs (145), SEO for
-- SMEs (144). A broad enterprise sweep would hijack ~1,700 searches for unrelated
-- courses. Only AI-qualified enterprise phrasings are included below.
--
-- Only fills empty redirects; never overwrites an intentional one.
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.

SET @t := 'https://www.tertiarycourses.com.sg/ai-applications-series.html';

-- Seed generic phrasings not already in the table.
INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (
    SELECT 'ai applications' AS q
    UNION ALL SELECT 'ai applications series'
    UNION ALL SELECT 'ai apps'
    UNION ALL SELECT 'ai app'
    UNION ALL SELECT 'ai application development'
    UNION ALL SELECT 'ai application course'
    UNION ALL SELECT 'ai applications course'
    UNION ALL SELECT 'build ai applications'
    UNION ALL SELECT 'building ai applications'
    UNION ALL SELECT 'ai enterprise'
    UNION ALL SELECT 'ai enterprises'
    UNION ALL SELECT 'ai for enterprise'
    UNION ALL SELECT 'ai for enterprises'
    UNION ALL SELECT 'enterprise ai'
    UNION ALL SELECT 'ai for business'
    UNION ALL SELECT 'ai in enterprise'
    UNION ALL SELECT 'ai aplications'      -- misspellings
    UNION ALL SELECT 'ai applicaton'
    UNION ALL SELECT 'ai appliations'
) v
WHERE EXISTS (
    SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore'
)
AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) e
    WHERE e.query_text = v.q
);

-- Point the GENERIC terms at the series category page.
UPDATE catalogsearch_query
SET redirect = @t
WHERE store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND query_text IN (
    'ai application','ai applications','ai applications series','ai apps','ai app',
    'ai application development','ai application course','ai applications course',
    'build ai applications','building ai applications',
    'ai enterprise','ai enterprises','ai for enterprise','ai for enterprises',
    'enterprise ai','ai for business','ai in enterprise',
    'ai aplications','ai applicaton','ai appliations'
  );
