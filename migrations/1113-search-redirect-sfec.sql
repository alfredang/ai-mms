-- Search-term redirect: "sfec" -> the SFEC funding page.
-- Applied live on SG prod 2026-08-25 (query_id 75889); this migration keeps a
-- rebuilt/restored DB in the same state. SG-only via the store-code guard;
-- no-op on partner sites (MY/GH have no sfec.html page).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/sfec.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%sfec%';
