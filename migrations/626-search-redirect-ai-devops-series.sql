-- 626: search redirect for "ai devops" / "ai mlops" + variants
--      -> AI Devops Series category page.
--
-- Verified: category 250 "AI Devops Series"; live page returns HTTP 200 with H1
-- "AI Devops Series" and lists 3 courses (AI Devops with Docker / Jenkins /
-- Kubernetes).
--
-- SCOPE NOTE -- the bare "devops" trap: 'devops' (530 searches), 'Azure DevOps'
-- (276), 'Devops essential training' (169), 'dev ops' (35), 'Aws devops' (27) are
-- NOT redirected here. Those users want the GENERAL DevOps catalog, which lives in
-- separate categories -- 304 "DevOps" and 351 "DevOps Certification Exam Prep" --
-- not the 3-course AI series. Sending them to the AI series would bury the Azure /
-- AWS / Foundation / Agile-Scrum courses they are actually looking for.
-- Only AI-qualified phrasings are redirected below.
--
-- 'mlops' IS included: MLOps is inherently ML/AI-specific, so the AI series is the
-- right destination for it.
--
-- Only fills empty redirects; never overwrites an intentional one.
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.

SET @t := 'https://www.tertiarycourses.com.sg/ai-devops-series.html';

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (
    SELECT 'ai devops' AS q
    UNION ALL SELECT 'ai dev ops'
    UNION ALL SELECT 'ai devops series'
    UNION ALL SELECT 'devops ai'
    UNION ALL SELECT 'ai mlops'
    UNION ALL SELECT 'ml ops'
    UNION ALL SELECT 'mlops course'
    UNION ALL SELECT 'mlops training'
    UNION ALL SELECT 'machine learning ops'
    UNION ALL SELECT 'machine learning operations'
    UNION ALL SELECT 'ai devops course'
    UNION ALL SELECT 'ai devops training'
    UNION ALL SELECT 'ai devops with docker'
    UNION ALL SELECT 'ai devops with jenkins'
    UNION ALL SELECT 'ai devops with kubernetes'
    UNION ALL SELECT 'ai devsecops'
    UNION ALL SELECT 'mlops ai'
    UNION ALL SELECT 'ml opts'          -- misspellings
    UNION ALL SELECT 'mlopps'
    UNION ALL SELECT 'ai devopts'
) v
WHERE EXISTS (
    SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore'
)
AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) e
    WHERE e.query_text = v.q
);

-- Point the AI-QUALIFIED terms at the series category page.
-- 'devops', 'dev ops', 'Azure DevOps', 'Aws devops' etc are deliberately absent.
UPDATE catalogsearch_query
SET redirect = @t
WHERE store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND query_text IN (
    'ai devops','ai dev ops','ai devops series','devops ai','ai mlops',
    'mlops','ml ops','mlops course','mlops training',
    'machine learning ops','machine learning operations',
    'ai devops course','ai devops training',
    'ai devops with docker','ai devops with jenkins','ai devops with kubernetes',
    'ai devsecops','mlops ai','ml opts','mlopps','ai devopts'
  );
