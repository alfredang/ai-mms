-- Search redirect: "power pivot" -> CASL Excel Power Query and Power Pivot (TGS-2026064177).
-- Applied live on SG prod 2026-11-10; this file keeps a rebuilt DB in the same state.
-- 1) Exact "power pivot" is a CORRECTION (was the non-WSQ C1097 masterclass) -> NULL-safe overwrite.
-- 2) Other power-pivot terms: fill EMPTY rows only, so intentional C1097 targets
--    (e.g. "Data Analytics Using Power Query and Power Pivot") are left alone.
SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-excel-power-query-and-power-pivot.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(TRIM(query_text)) = 'power pivot'
  AND NOT (redirect <=> @tgt);

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND REPLACE(LOWER(query_text), ' ', '') LIKE '%powerpivot%';
