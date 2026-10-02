-- 1699: on-site search "wix" and "notion" -> the Content Management category
-- page (content-management-cms-skillsfuture-courses.html), which now lists the
-- Wix and Notion courses directly (1695 / 1696 retired the Wix and Notion
-- category pages).
--
-- Requested 2026-10-02; supersedes the wix / notion course targets in 1697
-- (already shipped, so corrected here in a new file). Target checked 200 on SG
-- prod. NULL-safe overwrite guard, LIKE match. SG-only (store guard).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/content-management-cms-skillsfuture-courses.html';

UPDATE catalogsearch_query SET redirect = @tgt, num_results = 1, is_processed = 1
 WHERE @sg = 1 AND store_id = 1 AND NOT (redirect <=> @tgt)
   AND (LOWER(query_text) LIKE '%wix%' OR LOWER(query_text) LIKE '%notion%');
