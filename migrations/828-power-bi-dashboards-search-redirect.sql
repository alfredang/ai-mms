-- Search-term redirect: "WSQ - Miscrosoft Power BI for Data Analytics Dashboards, Reports & Insights"
-- (and any Microsoft/Miscrosoft spelling variant of the phrase) -> the WSQ Power BI course page.
-- Applied live on SG prod 2026-07-29; this migration keeps a rebuilt DB in the same state.
-- SG-only: store guard makes this a no-op on partner sites (WSQ course does not exist there).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-data-analytics-and-visualization-with-power-bi.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @tgt)
  AND LOWER(query_text) LIKE '%power bi for data analytics dashboards%';
