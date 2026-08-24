-- 1097: search-term redirect -> WSQ AI for Life Science and Bioinformatics
--
-- Applied LIVE on SG prod 2026-08-24 (2 rows: "ai for life science",
-- "ai for bioinformatics", both previously empty). This file exists so a
-- rebuilt/restored DB keeps the same state.
--
-- Scope is deliberately TIGHT. The site also sells "WSQ Bioinformatics Data
-- Analysis with R Bioconductor", and ~13 existing search rows correctly point
-- there. A bare '%bioinformatic%' pattern would hijack every one of them, so
-- we match only AI-flavoured life-science phrasings.
--
-- NOT (redirect <=> @tgt) is NULL-safe: it fills unset rows AND corrects wrong
-- ones, while no-opping on rows already correct. A bare <> would skip NULLs.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-for-life-science-and-bioinformatics.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
        LOWER(query_text) IN ('ai for life science', 'ai for bioinformatics')
     OR LOWER(query_text) LIKE '%life scien%'
     OR LOWER(query_text) LIKE '%lifescien%'
     OR LOWER(query_text) LIKE '%ai for life%'
     OR LOWER(query_text) LIKE '%ai for bioinformatic%'
  );
