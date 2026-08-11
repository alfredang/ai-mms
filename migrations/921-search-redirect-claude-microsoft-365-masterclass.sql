-- Redirect the "Claude Microsoft 365 Masterclass" on-site search term to the
-- course page. Applied live on SG prod 2026-08-12; this keeps a rebuilt DB in
-- the same state. SG-only (store guard makes partner sites a no-op).
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/claude-microsoft-365-masterclass.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @tgt)
  AND (LOWER(query_text) LIKE '%claude%microsoft 365%'
       OR LOWER(query_text) LIKE '%microsoft 365%claude%');
