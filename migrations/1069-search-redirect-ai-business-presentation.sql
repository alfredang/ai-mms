-- Follow-up to 1064: cover the "ai business presentation" wording (no "for"),
-- a row created on prod after 1064 was written. 1064 already applied on prod
-- so it can never re-run -- this must be a new numbered file.
-- SG-only (WSQ / TGS- course does not exist on partner sites).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-business-presentations.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%ai%business%presentation%';
