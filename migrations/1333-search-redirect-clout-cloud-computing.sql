-- Search-term redirect: "clout" (common typo of "cloud") -> Cloud Computing category.
-- SG store only; partner sites are a no-op via the store guard.
-- NULL-safe guard fills unset rows AND corrects wrong ones, no-ops when already correct.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/cloud-computing-courses.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%clout%';
