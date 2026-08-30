-- 1260: Search-term redirect — the exact term "leadership" goes to the
-- Leadership Training Courses category page.
-- Applied live on SG prod 2026-08-31 (query_id 754); this keeps a rebuilt DB in sync.
-- Scope is the exact term only: other %leadership% rows carry intentional
-- product-page redirects and must not be swept.
-- SG guard uses > 0 (count can be 2; see feedback_sg_guard_count_is_two_test_greater_than_zero).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/leadership-training-courses.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg > 0
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) = 'leadership';
