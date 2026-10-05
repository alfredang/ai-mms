-- Search term "Claude Solution Architect" -> WSQ Claude Certified Architect Foundation (TGS-2026061312).
-- Tight pattern only: generic "claude architect" variants also match the non-WSQ twin C437.
-- SG-only (WSQ course); NULL-safe guard fills empty rows and overwrites wrong ones.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-claude-certified-architect-foundation.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%claude solution% architect%';
