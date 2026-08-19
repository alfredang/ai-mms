-- Point "basic autocad" search variants at the WSQ Technical Drawing with AutoCAD course.
-- Corrects rows that previously pointed at the non-WSQ autocad-essential-training.html.
-- SG-only (store_id = 1); no-op on partner sites where the WSQ course does not exist.
-- NULL-safe guard: fills unset rows AND overwrites wrong ones, no-ops on already-correct.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-technical-drawing-with-autocad.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) LIKE '%basic%autocad%'
    OR LOWER(query_text) LIKE '%autocad%basic%');
