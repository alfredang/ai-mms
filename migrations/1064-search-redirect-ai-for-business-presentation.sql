-- Point "ai for business presentation" style search terms at the WSQ
-- Generative AI for Business Presentations course.
-- SG-only (WSQ / TGS- course does not exist on partner sites).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-business-presentations.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) LIKE '%ai for business presentation%'
    OR LOWER(query_text) LIKE '%wsq presentation%');
