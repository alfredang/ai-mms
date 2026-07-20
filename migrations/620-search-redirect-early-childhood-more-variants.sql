-- 620: further "early childhood" variants -> AI for Early Childhood course page.
-- Extends 618/619. Magento redirects are exact-match, so each phrasing needs a row.
-- Covers: role/audience phrasings (preschool teacher, kindergarten, childcare),
-- more misspellings, and "ai for ..." prefixed forms.
-- Only fills empty redirects; partner-safe via the SG store-code guard.

SET @t := 'https://www.tertiarycourses.com.sg/ai-for-early-childhood.html';

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (
    SELECT 'early childhoo' AS q
    UNION ALL SELECT 'early childood'
    UNION ALL SELECT 'early chldhood'
    UNION ALL SELECT 'early chidhood'
    UNION ALL SELECT 'earlychildhook'
    UNION ALL SELECT 'childhook'
    UNION ALL SELECT 'child hood'
    UNION ALL SELECT 'ece'
    UNION ALL SELECT 'ece course'
    UNION ALL SELECT 'preschool teacher'
    UNION ALL SELECT 'preschool teachers'
    UNION ALL SELECT 'pre school'
    UNION ALL SELECT 'pre-school'
    UNION ALL SELECT 'kindergarten'
    UNION ALL SELECT 'kindergarten teacher'
    UNION ALL SELECT 'childcare'
    UNION ALL SELECT 'child care'
    UNION ALL SELECT 'ai for preschool'
    UNION ALL SELECT 'ai for childcare'
    UNION ALL SELECT 'ai for early childhood education'
    UNION ALL SELECT 'ai in early childhood'
    UNION ALL SELECT 'ai early childhood'
) v
WHERE EXISTS (SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore')
AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) e
    WHERE e.query_text = v.q
);

UPDATE catalogsearch_query
SET redirect = @t
WHERE store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND query_text IN (
    'early childhoo','early childood','early chldhood','early chidhood',
    'earlychildhook','childhook','child hood','ece','ece course',
    'preschool teacher','preschool teachers','pre school','pre-school',
    'kindergarten','kindergarten teacher','childcare','child care',
    'ai for preschool','ai for childcare','ai for early childhood education',
    'ai in early childhood','ai early childhood'
  );
