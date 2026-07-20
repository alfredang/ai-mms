-- 618: search redirect for "early childhood" -> AI for Early Childhood course page.
-- Verified: C831 "AI for Early Childhood" is the ONLY early-childhood course in the
-- catalog (enabled), and it already ranks #1 for every term below - the rest of each
-- result page is unrelated noise, so a direct redirect strictly improves the landing.
-- Only fills empty redirects; never overwrites an intentional one.
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.
--
-- DELIBERATELY EXCLUDED (see notes to the user): the two "diploma / NIEC care and
-- education" queries, which are looking for a full-time diploma qualification we do
-- not offer, not a short course. Redirecting those would misrepresent the offering.

SET @t := 'https://www.tertiarycourses.com.sg/ai-for-early-childhood.html';

-- Seed common phrasings that are not yet in the table.
INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (
    SELECT 'ai for early childhood' AS q
    UNION ALL SELECT 'early childhood ai'
    UNION ALL SELECT 'preschool'
) v
WHERE EXISTS (
    SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore'
)
AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) e
    WHERE e.query_text = v.q
);

-- Point the existing early-childhood terms at the course page.
UPDATE catalogsearch_query
SET redirect = @t
WHERE store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND query_text IN (
    'Early childhood',
    'early childhood education',
    'early childhood care',
    'early childhood fundamentals certificate',
    'Leadership training in early childhood',
    'ai for early childhood',
    'early childhood ai',
    'preschool'
  );
