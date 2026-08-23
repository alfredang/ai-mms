-- Redirect generic "rpa" search terms to the RPA API IT Automation category page.
-- Explicit verified term list (not a bare LIKE '%rpa%') because "rpa" is a short
-- generic keyword: tool-specific terms (UiPath / Power Automate / Automation
-- Anywhere / WSQ beginners) keep their existing product-page redirects.
-- NULL-safe guard fills empty rows AND corrects wrong ones; no-ops when already set.
-- SG only (store guard): the target category exists only on the SG site.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/rpa-api-it-automation-courses.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) IN (
    'rpa',
    'rpas',
    'rpa course',
    'rpa training',
    'rpa automation',
    'rpa automate',
    'rpa course singapore',
    'rpa cert',
    'rpa robotics process automation',
    'rpa robotic',
    'basic rpa',
    'advanced rpa',
    'advance rpa',
    'rpa advance',
    'rpa advanced',
    'advanced rpa training',
    'advance rpa course'
  );
