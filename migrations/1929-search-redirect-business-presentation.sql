-- Search redirect: "business presentation(s)" / "ai business presentation(s)" (any spacing/hyphens)
--   -> WSQ - Generative AI for Business Presentations (TGS-2026061325).
-- Applied live on SG prod 2026-11-14; this file keeps a rebuilt DB in the same state.
-- Exact normalised terms only: the non-WSQ twin C329 "Generative AI for Business Presentation"
-- keeps its own title searchable. SG-only (TGS- course); no-op on partner sites.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-generative-ai-for-business-presentations.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND REPLACE(REPLACE(LOWER(TRIM(query_text)), '-', ''), ' ', '') IN
      ('businesspresentation', 'businesspresentations',
       'aibusinesspresentation', 'aibusinesspresentations');
