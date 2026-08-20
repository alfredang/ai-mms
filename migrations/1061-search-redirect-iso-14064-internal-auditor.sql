-- Point "ISO 14064 internal auditor" search terms at the WSQ ISO 14064 Internal
-- Auditor course.
--
-- Correction, not a fill: on SG prod four of these rows pointed at
-- wsq-iso-45001-internal-auditor-training.html (ISO 45001 = occupational health
-- & safety), a different course entirely. NOT (redirect <=> @tgt) is the
-- NULL-safe guard -- it overwrites those wrong rows AND fills any unset ones,
-- while no-opping on rows already correct.
--
-- Scope is deliberately tight: 14064 AND an "internal audit(or)" phrase. Bare
-- "14064" / "ISO 14064" / the "14064-1:2018" GHG variants are left alone --
-- they belong to the separate GHG Emissions and Removals course and the ISO
-- standards category page.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-iso-14064-internal-auditor-training.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%14064%'
  AND (LOWER(query_text) LIKE '%internal audit%'
    OR LOWER(query_text) LIKE '%internal auit%');
