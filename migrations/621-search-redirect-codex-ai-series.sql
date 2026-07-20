-- 621: search redirect for "codex" + variants -> Codex AI Series category page.
--
-- Verified: category 283 "Codex AI Series" (url_key codex-ai-series) is active and
-- holds 3 enabled courses (C818 AI Vibe Coding with Codex, C427 Codex for Work
-- Automation, C989 Codex Masterclass). A generic "codex" search previously ranked
-- Codex Masterclass #1 organically -- there was NO existing redirect, so nothing
-- intentional is overwritten here. Landing on the series category shows all three
-- courses instead of arbitrarily picking one.
--
-- DELIBERATELY EXCLUDED: exact course-title searches ("codex masterclass",
-- "codex for work automation", "ai vibe coding with codex"). Those name a specific
-- course, and bouncing that user to a category listing would be a downgrade.
--
-- Only fills empty redirects; never overwrites an intentional one.
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.

SET @t := 'https://www.tertiarycourses.com.sg/codex-ai-series.html';

-- Seed the generic / variant phrasings that are not in the table yet.
INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (
    SELECT 'codex' AS q
    UNION ALL SELECT 'codex ai'
    UNION ALL SELECT 'codex ai series'
    UNION ALL SELECT 'ai codex'
    UNION ALL SELECT 'openai codex'
    UNION ALL SELECT 'open ai codex'
    UNION ALL SELECT 'codex course'
    UNION ALL SELECT 'codex courses'
    UNION ALL SELECT 'codex training'
    UNION ALL SELECT 'codex series'
    UNION ALL SELECT 'codex cli'
    UNION ALL SELECT 'codex coding'
    UNION ALL SELECT 'coding with codex'
    UNION ALL SELECT 'codec'          -- common misspelling of codex
    UNION ALL SELECT 'codek'
    UNION ALL SELECT 'codx'
    UNION ALL SELECT 'cdoex'          -- transposed
) v
WHERE EXISTS (
    SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore'
)
AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) e
    WHERE e.query_text = v.q
);

-- Point the generic terms at the series category page.
UPDATE catalogsearch_query
SET redirect = @t
WHERE store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND query_text IN (
    'codex','codex ai','codex ai series','ai codex','openai codex','open ai codex',
    'codex course','codex courses','codex training','codex series','codex cli',
    'codex coding','coding with codex','codec','codek','codx','cdoex'
  );
