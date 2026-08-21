-- Redirect on-site search for "Generative AI for Curriculum Development" to the course page.
-- SG store only; partner sites no-op via the store guard.
-- NULL-safe guard: fills unset rows AND overwrites wrong ones, no-ops on correct ones.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/generative-ai-for-curriculum-development.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%curriculum development%';
