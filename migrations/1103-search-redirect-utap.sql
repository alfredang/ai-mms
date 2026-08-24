-- 1103: search-term redirect -> the NTUC UTAP funding page (utap.html, added in 1101/1102)
--
-- Applied LIVE on SG prod 2026-08-24 (2 rows: "utap" pop=8, "utap ai" pop=1,
-- both previously empty). This file exists so a rebuilt/restored DB keeps the
-- same state. Ships together with the MMD_SearchFallback fix that stops the
-- controller from clearing redirects whose target is a CMS page with a .html
-- identifier — without that fix this redirect is silently nulled on first use.
--
-- Scope is deliberately TIGHT: only standalone/funding-intent UTAP phrasings.
-- Compound "utap <course topic>" rows are course-intent searches and are left
-- alone ("utap tableau" stays on search results; "Arduino utap" keeps its
-- existing product-page redirect).
--
-- NOT (redirect <=> @tgt) is NULL-safe: it fills unset rows AND corrects wrong
-- ones, while no-opping on rows already correct. A bare <> would skip NULLs.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/utap.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
        LOWER(query_text) IN ('utap', 'utap ai')
     OR LOWER(query_text) LIKE 'ntuc utap%'
     OR LOWER(query_text) LIKE 'utap claim%'
     OR LOWER(query_text) LIKE 'utap funding%'
     OR LOWER(query_text) LIKE 'utap subsidy%'
     OR LOWER(query_text) LIKE 'union training assistance%'
  );
