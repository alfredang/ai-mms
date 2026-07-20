-- 616: search redirect for course code "C523" -> PMP Exam Prep course page.
-- Verified: SKU C523 = "Project Management Professional (PMP) Exam Prep" (entity_id 523).
-- Only fills empty redirects; never overwrites an intentional one.
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.

SET @t := 'https://www.tertiarycourses.com.sg/project-management-professional-pmp-exam-prep.html';

-- Seed the lowercase variant if a learner types it that way (query_text collation is
-- case-insensitive, so this only inserts when neither casing exists yet).
INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (SELECT 'c523' AS q) v
WHERE EXISTS (
    SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore'
)
AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) e
    WHERE e.query_text = v.q
);

-- Point the existing C523 term at the course page.
UPDATE catalogsearch_query
SET redirect = @t
WHERE store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND query_text = 'C523';
