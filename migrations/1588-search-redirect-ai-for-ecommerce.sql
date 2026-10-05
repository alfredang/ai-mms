-- Search redirect: "ai for ecommerce" (and variants "ai e-commerce",
-- "ai ecommerce", "ai for e-commerce") -> AI for Retail category page.
-- Applied live on SG prod 2026-09-28; this keeps a rebuilt DB in sync.
-- NULL-safe guard fills empty rows AND overwrites the stale
-- ai-for-healthcare target on "ai e-commerce". Tight anchored pattern so
-- unrelated eCommerce terms are untouched. SG-only.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/ai-for-retail-courses.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) REGEXP '^ai (for )?e-? ?commerce$';
