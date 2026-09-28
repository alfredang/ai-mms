-- Search redirect: "ai fo(r) short video production" / "Create Short Video Film using AI"
-- -> WSQ Create Short Video Film using AI (TGS-2020505925). Applied live on SG prod 2026-09-28.
-- Tight pattern: only rows containing "short video" (3 on prod). NULL-safe guard fills + corrects.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-create-short-video-film-using-ai.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%short video%';
