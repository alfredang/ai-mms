-- 627: search redirect for "ai security" / "ai cyber security" + variants
--      -> AI Security Series category page.
--
-- Verified: live page https://www.tertiarycourses.com.sg/ai-security-series.html
-- returns HTTP 200 with H1 "AI Security Series" and lists AI-ethics / responsible-AI
-- / AI-governance courses plus "AI for Cyber Security".
--
-- SCOPE NOTE -- the bare "cyber security" trap: 'cyber security' (851 searches),
-- 'cyber' (451), 'cybersecurity' (397), 'Basic Cyber Security Course' (415),
-- 'Advanced Cyber Security Course' (244), 'network security' (166) and the WSQ cyber
-- awareness titles are NOT redirected here. Those ~2,400 searches belong to the
-- GENERAL cyber-security catalog, not to a series that is mostly AI ethics /
-- responsible AI / AI governance. Redirecting them would bury the courses those
-- learners actually want. Only AI-qualified phrasings are redirected below.
--
-- Only fills empty redirects; never overwrites an intentional one.
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.

SET @t := 'https://www.tertiarycourses.com.sg/ai-security-series.html';

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (
    SELECT 'ai security' AS q
    UNION ALL SELECT 'ai security series'
    UNION ALL SELECT 'ai cyber security'
    UNION ALL SELECT 'ai cybersecurity'
    UNION ALL SELECT 'ai cyber'
    UNION ALL SELECT 'security ai'
    UNION ALL SELECT 'ai for cyber security'
    UNION ALL SELECT 'ai for cybersecurity'
    UNION ALL SELECT 'ai for security'
    UNION ALL SELECT 'ai in cyber security'
    UNION ALL SELECT 'ai governance'
    UNION ALL SELECT 'ai ethics'
    UNION ALL SELECT 'responsible ai'
    UNION ALL SELECT 'ai safety'
    UNION ALL SELECT 'ai risk'
    UNION ALL SELECT 'ai security course'
    UNION ALL SELECT 'ai security training'
    UNION ALL SELECT 'ai security and governance'
    UNION ALL SELECT 'ai secuirty'        -- misspellings
    UNION ALL SELECT 'ai securty'
    UNION ALL SELECT 'ai cybersecuirty'
) v
WHERE EXISTS (
    SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore'
)
AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) e
    WHERE e.query_text = v.q
);

-- Point the AI-QUALIFIED terms at the series category page.
-- 'cyber security', 'cyber', 'cybersecurity', 'network security' etc are absent.
UPDATE catalogsearch_query
SET redirect = @t
WHERE store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND query_text IN (
    'ai security','ai security series','ai cyber security','ai cybersecurity','ai cyber',
    'security ai','ai for cyber security','ai for cybersecurity','ai for security',
    'ai in cyber security','ai governance','ai ethics','responsible ai','ai safety',
    'ai risk','ai security course','ai security training','ai security and governance',
    'ai secuirty','ai securty','ai cybersecuirty'
  );
