-- Point every "infographic*" on-site search term at the live CASL Infographics
-- and Data Visualization with PowerPoint course.
--
-- Why: the previously-populated targets had rotted. Nine rows (incl. the top
-- term "infographics", popularity 106) pointed at create-infographics-with-powerpoint.html,
-- whose slug has since been repurposed and now 301s to claude-microsoft-365-masterclass.html.
-- Two more pointed at r-data-visualization-training.html, now 301ing to ai-for-retail.html.
-- Searchers looking for infographics training were landing on unrelated courses.
--
-- Product 593 (CASL - Infographics and Data Visualization with PowerPoint,
-- status = 1) is the only live infographics course, so it is the single correct
-- target. The WSQ-prefixed URL 301s here; we point straight at the final slug
-- so users take one hop.
--
-- This is a CORRECTION, not a fill: it must overwrite the existing wrong
-- values, so the guard is `redirect <> @tgt` rather than the empty-only guard.
-- Matched by LIKE so typo/paren variants and rows created later are covered.
--
-- Applied live on SG prod 2026-08-15 (14 rows). SG-only; store guard makes this
-- a no-op on partner sites.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-infographics-and-data-visualization-with-powerpoint.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND redirect <> @tgt
  AND LOWER(query_text) LIKE '%infographic%';
