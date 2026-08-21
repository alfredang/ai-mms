-- Point the bare search term "14064" at the WSQ ISO 14064 Internal Auditor course.
--
-- Follow-up to 1061, which handled the "14064 + internal auditor" phrasings.
-- On SG prod this row pointed at the iso-standards-courses.html category page.
--
-- EXACT-MATCH ONLY -- deliberately not a LIKE. Two live ISO 14064 courses share
-- this number, and the sibling rows belong to the OTHER one:
--   "ISO 14064"        (pop 10) -> GHG Emissions and Removals course
--   "ISO 14064-1:2018" variants -> GHG Emissions and Removals course
-- 14064-1:2018 is specifically the GHG part of the standard, so a %14064%
-- sweep would hijack the GHG course's own search entries. Scope confirmed with
-- the user 2026-08-21: bare "14064" only.
--
-- NOT (redirect <=> @tgt) is the NULL-safe guard: it overwrites the wrong
-- category-page value AND fills the row if a rebuilt DB has it unset, while
-- no-opping when already correct.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-iso-14064-internal-auditor-training.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND TRIM(LOWER(query_text)) = '14064';
