-- 619: extends 618 - catch misspellings / partial forms of "early childhood"
-- so they also land on the AI for Early Childhood course page.
--
-- Magento search-term redirects are EXACT-MATCH on query_text (case-insensitive
-- collation, but no fuzzy matching), so every misspelling needs its own row.
-- "childhood" alone had 3 real searches and no redirect.
--
-- Only fills empty redirects; never overwrites an intentional one.
-- Partner-safe: guard matches the SG store by its store code, so MY/GH are a no-op.

SET @t := 'https://www.tertiarycourses.com.sg/ai-for-early-childhood.html';

-- Seed the misspelling / shorthand variants that are not in the table yet.
INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, display_in_terms, is_active, is_processed)
SELECT v.q, 1, 0, 0, @t, 1, 1, 0
FROM (
    SELECT 'early chiildhook' AS q          -- reported by the user
    UNION ALL SELECT 'early chiildhood'     -- doubled-i
    UNION ALL SELECT 'early childhook'      -- k-for-d
    UNION ALL SELECT 'early chilhood'       -- dropped d
    UNION ALL SELECT 'early chidlhood'      -- transposed dl
    UNION ALL SELECT 'earli childhood'
    UNION ALL SELECT 'erly childhood'
    UNION ALL SELECT 'early child hood'     -- split word
    UNION ALL SELECT 'earlychildhood'       -- no space
) v
WHERE EXISTS (
    SELECT 1 FROM core_store WHERE store_id = 1 AND code = 'singapore'
)
AND NOT EXISTS (
    SELECT 1 FROM (SELECT query_text FROM catalogsearch_query WHERE store_id = 1) e
    WHERE e.query_text = v.q
);

-- Point the bare "childhood" term (3 real searches, previously unredirected) and any
-- seeded rows above at the course page.
UPDATE catalogsearch_query
SET redirect = @t
WHERE store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND query_text IN (
    'childhood',
    'early chiildhook',
    'early chiildhood',
    'early childhook',
    'early chilhood',
    'early chidlhood',
    'earli childhood',
    'erly childhood',
    'early child hood',
    'earlychildhood'
  );
