-- Search term "power automate masterclass" -> C1063 Microsoft Power Automate Essential Training.
-- Applied live on SG prod 2026-09-30; this keeps a rebuilt DB in the same state. SG-only guard.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/microsoft-power-automate-essential-training.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%power automate%master%class%';
