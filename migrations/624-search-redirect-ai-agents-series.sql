-- 624: search redirect for "ai agents" / "agentic ai" + variants
--      -> AI Agents Series category page.
--
-- Verified: https://www.tertiarycourses.com.sg/ai-agents-series.html returns HTTP 200
-- and serves H1 "AI Agents Series".
--
-- "Agentic ai" alone has 489 searches and "agentic" 224 -- the highest-traffic terms
-- in this batch, all previously unredirected.
--
-- SCOPE NOTE: as with 623, the long exact course-title queries are deliberately left
-- on normal search results, e.g. "Building Agentic AI Workflows to Automate Business
-- Processes", "Agentic AI Automation with n8n", "Mastering AI Agentic RAG and
-- Workflows with No Code" and their WSQ- prefixed twins. Those name one specific
-- course; bouncing them to a category listing would be a downgrade.
--
-- Only fills empty redirects; never overwrites an intentional one.
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.

SET @t := 'https://www.tertiarycourses.com.sg/ai-agents-series.html';

-- Seed generic phrasings not already in the table.
INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (
    SELECT 'ai agents series' AS q
    UNION ALL SELECT 'agentic ai course'
    UNION ALL SELECT 'agentic ai courses'
    UNION ALL SELECT 'agentic ai training'
    UNION ALL SELECT 'ai agent course'
    UNION ALL SELECT 'ai agent courses'
    UNION ALL SELECT 'ai agent training'
    UNION ALL SELECT 'agentic course'
    UNION ALL SELECT 'agentic workflow'
    UNION ALL SELECT 'agentic workflows'
    UNION ALL SELECT 'agentic automation'
    UNION ALL SELECT 'autonomous agents'
    UNION ALL SELECT 'autonomous ai agents'
    UNION ALL SELECT 'multi agent'
    UNION ALL SELECT 'multi agents'
    UNION ALL SELECT 'multi-agent'
    UNION ALL SELECT 'agentic a i'
    UNION ALL SELECT 'agentric ai'      -- misspellings
    UNION ALL SELECT 'agenetic ai'
    UNION ALL SELECT 'agentik ai'
    UNION ALL SELECT 'ai agentz'
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
    'agentic ai','agentic','ai agent','ai agents','agent','agents','ai agentic',
    'agentic ai automation','ai agents series',
    'agentic ai course','agentic ai courses','agentic ai training',
    'ai agent course','ai agent courses','ai agent training',
    'agentic course','agentic workflow','agentic workflows','agentic automation',
    'autonomous agents','autonomous ai agents',
    'multi agent','multi agents','multi-agent','agentic a i',
    'agentric ai','agenetic ai','agentik ai','ai agentz'
  );
