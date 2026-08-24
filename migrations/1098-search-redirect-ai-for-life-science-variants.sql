-- 1098: broaden the "AI for Life Science" search redirect (follow-up to 1097)
--
-- 1097 matched only exact AI-flavoured phrasings, so plain variants
-- ("life science", "ai for life sciences", "AI for Life Science and
-- Bioinformatics", "Life Sciences") still fell through to a results page.
-- Each novel phrasing creates a NEW catalogsearch_query row with an empty
-- redirect, so a narrow pattern keeps leaking. Widened to the topic keyword.
--
-- 1097 is already in the ledger and never re-runs, hence a new file.
-- Applied live on SG prod 2026-08-24 (7 rows now point at the target).
--
-- Still deliberately EXCLUDES a bare '%bioinformatic%': 19 rows correctly
-- point at "WSQ Bioinformatics Data Analysis with R Bioconductor" (a
-- different course) and must stay that way. Only 'ai for bio%' is claimed.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-for-life-science-and-bioinformatics.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
        LOWER(query_text) LIKE '%life scien%'
     OR LOWER(query_text) LIKE '%lifescien%'
     OR LOWER(query_text) LIKE '%ai for bio%'
  );
