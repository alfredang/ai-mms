-- Point ISO 45001 on-site search terms at the WSQ ISO 45001 Internal Auditor course.
-- SG-only (store_id 1); no-op on partner sites via the store guard.
-- NULL-safe guard fills empty rows AND corrects wrong ones, no-ops on correct ones.
-- '45001' is a distinctive token: no other course on the catalog matches it.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-iso-45001-internal-auditor-training.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%45001%';
