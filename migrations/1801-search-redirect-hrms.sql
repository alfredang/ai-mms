-- Search redirect: 'HRMS' -> CASL - Managing Human Resource Management System (HRMS)
-- (TGS-2026066579). Applied live on SG prod 2026-10-10; this keeps a rebuilt DB in step.
-- SG-only (store guard); NULL-safe guard fills unset rows and overwrites wrong ones.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-managing-human-resource-management-system-hrms.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%hrms%';
