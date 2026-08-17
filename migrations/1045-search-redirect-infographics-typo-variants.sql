-- Search-term redirect: MISSPELLED infographics terms -> CASL Infographics and
-- Data Visualization with PowerPoint (SG only).
--
-- Applied live on SG prod 2026-08-17.
--
-- Why this exists: migrations 1036/1043 matched '%infograph%', which cannot
-- match the common r/o transposition "inforgraphics" (info-R-graphics). A user
-- searching "ai inforgraphics" got 507 unfiltered results. Substring patterns
-- only ever cover the spellings you thought of -- misspellings are their own
-- class of miss, not an oversight in the earlier files.
--
-- Also repaired here: "create inforgraphics with powerpoint" (query_id 47846)
-- pointed at create-infographics-with-powerpoint.html, whose slug has since
-- been repurposed and now 301-chains to claude-microsoft-365-masterclass.html
-- -- an unrelated course. That is target rot, not a data-entry error.
--
-- NOT (redirect <=> @tgt) is NULL-safe -- a plain `redirect <> @tgt` silently
-- skips rows whose redirect IS NULL.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-infographics-and-data-visualization-with-powerpoint.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
        LOWER(query_text) LIKE '%infograph%'    -- correct spelling (re-assert)
     OR LOWER(query_text) LIKE '%inforgraph%'   -- info-R-graph  (r/o swap)
     OR LOWER(query_text) LIKE '%infogrpah%'    -- infogr-PAH    (a/h swap)
     OR LOWER(query_text) LIKE '%infograpic%'   -- missing h
     OR LOWER(query_text) LIKE '%infografic%'   -- phonetic f
     OR LOWER(query_text) LIKE '%inforgaphic%'  -- r moved, no r
  );

-- Seed the typo terms so a rebuilt DB carries them before anyone searches.
INSERT IGNORE INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'ai inforgraphics', 1, 1, 1, @tgt, 1 FROM DUAL WHERE @sg = 1;

INSERT IGNORE INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'inforgraphics', 1, 1, 1, @tgt, 1 FROM DUAL WHERE @sg = 1;

INSERT IGNORE INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'inforgraphic', 1, 1, 1, @tgt, 1 FROM DUAL WHERE @sg = 1;
