-- Search-term redirect: generic "customer service" searches -> the Customer
-- Service Training catalog (category) page.
--
-- Applied LIVE on SG prod 2026-08-18 (5 rows); this migration keeps a
-- rebuilt/restored DB in the same state.
--
-- Pattern is a PREFIX match ('customer service%'), deliberately NOT
-- '%customer service%': course-title searches ("WSQ Improve Your Business with
-- Excellent Customer Service", "Build a Generative AI LLM-Powered Chatbot to
-- Enhance Customer Service", ...) all start with other words and keep their
-- intentional course-page redirects.
--
-- NULL-safe guard NOT (redirect <=> @tgt): fills empty rows AND overwrites
-- wrong ones, no-ops on rows already correct. SG-only via the store guard
-- (partner sites have no such category target).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/customer-service-training.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE 'customer service%';
