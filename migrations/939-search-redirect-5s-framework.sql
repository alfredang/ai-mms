-- Redirect the "5S" on-site search terms to the WSQ 5S Framework course page.
-- Applied live on SG prod 2026-08-13; this keeps a rebuilt DB in the same state.
-- Only one live course matches "5S" (TGS- WSQ Maximizing Productivity Outcomes
-- Using 5S Framework), so the generic bare term is safe to redirect -- there is
-- no sibling course being hidden from search results.
-- SG-only (store guard makes partner sites a no-op; WSQ/TGS- is SG-only).
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-maximizing-productivity-outcomes-using-5s-framework.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @tgt)
  AND LOWER(query_text) LIKE '%5s%';
