-- Search redirect: "Microsoft Endpoint Administrator (MD-102)" and other
-- endpoint-administrator title variants -> the WSQ MD-102 course page.
-- Applied live on SG prod 2026-08-25 (query_id 78083 was the empty row the
-- user hit); this migration keeps a rebuilt/restored DB in the same state.
-- Exam-prep-worded terms are deliberately excluded — they point at the
-- sibling non-WSQ md-102-...-exam-prep.html course.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-microsoft-certified-endpoint-administrator-associate-md-102.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%endpoint admin%'
  AND LOWER(query_text) NOT LIKE '%exam prep%';
