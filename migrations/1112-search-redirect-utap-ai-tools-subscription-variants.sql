-- 1112: search redirect - "utap ai tools subscription" (plural) + typo variant
-- to the UTAP page. 1105 covered the singular "utap ai tool subscription";
-- these rows were created by searchers after it shipped. Applied LIVE on SG
-- prod 2026-08-25; this migration keeps a rebuilt DB consistent.
-- Tight prefix pattern: matches 'utap ai%' only, so intentional redirects like
-- "Arduino utap" (product page) and the un-redirected "utap tableau" are
-- untouched. NULL-safe guard fills empty rows AND corrects wrong ones.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/utap.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE 'utap ai%';
