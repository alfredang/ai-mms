-- 842: Repoint search-term redirects from C469's old url_key to the new one
-- (Tableau Desktop Intermediate Training -> Tableau Desktop Masterclass, see 841).
-- REPLACE swaps only the path, preserving each store's own domain (partner-safe).
-- Idempotent: rows already repointed no longer match the WHERE.

UPDATE catalogsearch_query
SET redirect = REPLACE(redirect, 'full-tableau-data-visualization-training.html', 'tableau-desktop-masterclass.html')
WHERE redirect LIKE '%full-tableau-data-visualization-training.html%';
