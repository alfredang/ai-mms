-- 623: search redirect for "genai" / "generative ai" + variants
--      -> Generative AI Series category page.
--
-- Verified: category 433 is named "Generative AI Series" (104 products). Locally its
-- url_key is still the older 'generative-ai-gai-llm-courses'; on production it has
-- been renamed to 'generative-ai-series' and the live page serves H1 "Generative AI
-- Series" with HTTP 200. The redirect stores the absolute production URL, so it is
-- correct on prod regardless of the stale local url_key.
--
-- SCOPE NOTE: 429 terms match %genai%/%gen ai%/%generative% (3,316 searches), but
-- 313 of them (1,949 searches) are LONG exact course-title queries such as
-- "WSQ - Digital Marketing with Generative AI". Those name one specific course and
-- must keep returning normal search results -- redirecting them to a 104-product
-- category listing would be a downgrade. This migration therefore lists the generic
-- terms EXPLICITLY rather than using a blunt LIKE sweep.
--
-- Only fills empty redirects; never overwrites an intentional one.
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.

SET @t := 'https://www.tertiarycourses.com.sg/generative-ai-series.html';

-- Seed generic phrasings not already in the table.
INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (
    SELECT 'generative ai series' AS q
    UNION ALL SELECT 'gen-ai'
    UNION ALL SELECT 'gen a i'
    UNION ALL SELECT 'genai course'
    UNION ALL SELECT 'genai courses'
    UNION ALL SELECT 'genai training'
    UNION ALL SELECT 'generative ai course'
    UNION ALL SELECT 'generative ai courses'
    UNION ALL SELECT 'generative ai training'
    UNION ALL SELECT 'generative a.i'
    UNION ALL SELECT 'genrative ai'      -- misspellings
    UNION ALL SELECT 'genarative ai'
    UNION ALL SELECT 'generatve ai'
    UNION ALL SELECT 'geneartive ai'
    UNION ALL SELECT 'genai ai'
    UNION ALL SELECT 'gena i'
) v
WHERE EXISTS (
    SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore'
)
AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) e
    WHERE e.query_text = v.q
);

-- Point the GENERIC terms at the series category page.
-- Deliberately excluded: every long exact course-title query (see SCOPE NOTE).
UPDATE catalogsearch_query
SET redirect = @t
WHERE store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND query_text IN (
    'genai','generative ai','gen ai','generative','ai generative','generative ai tools',
    'genai tools','generative ai series','gen-ai','gen a i',
    'genai course','genai courses','genai training',
    'generative ai course','generative ai courses','generative ai training',
    'generative a.i','genrative ai','genarative ai','generatve ai','geneartive ai',
    'genai ai','gena i'
  );
