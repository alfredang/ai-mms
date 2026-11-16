-- Search "CCAR-F", "CCAR", "Claude Certified Architect Foundation" (and variants)
-- -> WSQ Claude Certified Architect Foundation course (TGS-2026061312).
-- Already applied LIVE on SG prod 2026-11-08; this keeps a rebuilt DB in the same state.
-- SG-only; NULL-safe guard fills empty rows and overwrites wrong ones.
-- Match on the term with spaces/hyphens stripped. Searches for the C437 exam-prep
-- title ("... (CCAR-F) Exam Prep") are excluded so that course stays findable.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-claude-certified-architect-foundation.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
        REPLACE(REPLACE(LOWER(TRIM(query_text)), '-', ''), ' ', '') IN ('ccar', 'ccarf')
     OR (    REPLACE(REPLACE(LOWER(TRIM(query_text)), '-', ''), ' ', '') LIKE '%claudecertifiedarchitectfoundation%'
         AND LOWER(query_text) NOT LIKE '%exam%'
         AND LOWER(query_text) NOT LIKE '%prep%')
  );
