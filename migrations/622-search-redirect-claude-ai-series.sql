-- 622: search redirect for "claude" + variants -> Claude AI Series category page.
--
-- Verified: category 281 "Claude AI Series" (url_key claude-ai-series) is active and
-- holds 10 enabled courses -- a superset that already includes all 4 courses in the
-- separate Claude certification-exam-prep category (370), so it is the correct
-- generic landing. "claude" alone had 36 searches with no redirect.
--
-- DELIBERATELY EXCLUDED: exact course-title searches, which name one specific
-- course and would be downgraded by a category bounce --
--   'Agentic AI Applications with Claude Code', 'agentic coding with claude code',
--   'Claude Code marketing', 'claude financial'
-- Also excluded: certification/exam-prep phrasings, which belong to category 370.
--
-- Only fills empty redirects; never overwrites an intentional one.
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.

SET @t := 'https://www.tertiarycourses.com.sg/claude-ai-series.html';

-- Seed the generic / variant phrasings that are not in the table yet.
INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (
    SELECT 'claude ai' AS q
    UNION ALL SELECT 'claude ai series'
    UNION ALL SELECT 'ai claude'
    UNION ALL SELECT 'anthropic'
    UNION ALL SELECT 'anthropic claude'
    UNION ALL SELECT 'claude course'
    UNION ALL SELECT 'claude courses'
    UNION ALL SELECT 'claude training'
    UNION ALL SELECT 'claude series'
    UNION ALL SELECT 'claude cli'
    UNION ALL SELECT 'claude opus'
    UNION ALL SELECT 'claude sonnet'
    UNION ALL SELECT 'claude desktop'
    UNION ALL SELECT 'claude agent'
    UNION ALL SELECT 'claude agents'
    UNION ALL SELECT 'clade'            -- common misspellings
    UNION ALL SELECT 'claud'
    UNION ALL SELECT 'cluade'
    UNION ALL SELECT 'claude ai course'
    UNION ALL SELECT 'claude automation'
) v
WHERE EXISTS (
    SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore'
)
AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) e
    WHERE e.query_text = v.q
);

-- Point the generic terms at the series category page. 'claude code', 'claude ios'
-- and 'claude coding' are generic product/topic names (not course titles), so they
-- are included; the four exact course-title terms above are not.
UPDATE catalogsearch_query
SET redirect = @t
WHERE store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND query_text IN (
    'claude','claude ai','claude ai series','ai claude','anthropic','anthropic claude',
    'claude course','claude courses','claude training','claude series','claude cli',
    'claude opus','claude sonnet','claude desktop','claude agent','claude agents',
    'clade','claud','cluade','claude ai course','claude automation',
    'claude code','claude ios','claude coding'
  );
