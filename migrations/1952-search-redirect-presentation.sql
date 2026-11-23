-- 1952 — Search-term redirect: "presentation" / "presentations" (alone) -> the WSQ
-- Generative AI for Business Presentations course. Complements 1929 (business
-- presentation variants). Data fix: apply LIVE on SG prod as well as keeping this file.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-business-presentations.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) IN ('presentation', 'presentations');

-- Make sure a row exists even if nobody has searched the term yet.
INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed, updated_at)
SELECT t.q, 1, 1, @tgt, 1, 0, 1, 1, NOW()
FROM (SELECT 'presentation' AS q UNION SELECT 'presentations') t
WHERE @sg = 1
  AND NOT EXISTS (SELECT 1 FROM catalogsearch_query c WHERE c.store_id = 1 AND LOWER(c.query_text) = t.q);
