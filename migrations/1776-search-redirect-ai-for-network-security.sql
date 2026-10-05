-- Search-term redirects -> WSQ AI for Network Security (TGS-2024051414).
-- Terms: "Application for AI for Network Security", "network security ai"
-- (+ any "%ai for network security%" variant). Applied live on SG prod 2026-10-05.
-- NULL-safe guard fills empty rows and overwrites wrong ones. SG-only.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-for-network-security.html';

INSERT INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed, updated_at)
SELECT 'network security ai', 1, 1, @tgt, 1, 1, 1, 1, NOW() FROM DUAL
WHERE @sg = 1
  AND NOT EXISTS (SELECT 1 FROM catalogsearch_query WHERE store_id = 1 AND LOWER(query_text) = 'network security ai');

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) IN ('application for ai for network security', 'network security ai')
       OR LOWER(query_text) LIKE '%ai for network security%');
