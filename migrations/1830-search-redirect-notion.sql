-- Search terms containing "notion" -> the WSQ Notion course (TGS-2023041080).
-- They previously pointed at the Content Management category page; the non-WSQ
-- twin C009 is retired (status 2), so there is no sibling course to hide.
-- Applied live on SG prod 2026-10-18 (10 rows). NULL-safe guard fills unset
-- rows and overwrites wrong ones. SG-only: the target is a TGS- course.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-mastering-notion-for-content-project-and-database-management.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%notion%';
