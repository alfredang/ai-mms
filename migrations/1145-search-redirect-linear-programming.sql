-- 1145: Redirect "linear programming" / "linear optimization" search terms to the
-- WSQ Decision-Making and Resource Optimization with Linear Programming course.
-- Applied live on SG prod 2026-08-28; this migration keeps the state on a rebuilt DB.
-- NULL-safe guard fills empty rows AND corrects wrong ones (e.g. the full course
-- title previously pointed at wsq-resource-management-optimisation.html).
-- Patterns are tight: they exclude "linear algebra" and the bare term "Linear".

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-decision-making-and-resource-optimization-with-linear-programming.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) LIKE '%linear program%'
    OR LOWER(query_text) LIKE '%linear optimi%');
