-- Search-term redirect: generic "arduino" -> WSQ - Practical Electronics Design
-- with Arduino Microcontroller (TGS-2020506075). SG only.
--
-- Applied live on SG prod 2026-08-29; this file only preserves that state for a
-- rebuilt/restored DB.
--
-- SCOPE IS DELIBERATELY NARROW. Prod carries ~120 %arduino% rows, and the great
-- majority already point at a MORE SPECIFIC, still-live target:
--   * arduino-essential-training-in-singapore.html   (~70 rows)
--   * advanced-arduino-training.html                 (~6 rows)
--   * wsq-ai-assisted-c-programming-for-arduino.html (~5 rows)
--   * arduino-courses-in.html (the Arduino category listing)
--   * tertiaryrobotics.com product pages (kits/parts, not courses)
-- A bare `LIKE '%arduino%'` sweep would clobber every one of those and hide
-- three live courses from on-site search. So this is an explicit verified term
-- list of GENERIC arduino queries only -- terms that name no particular course.
--
-- NULL-safe guard `NOT (redirect <=> @tgt)` fills unset rows AND overwrites
-- wrong ones, while no-opping on rows already correct. A bare `redirect <> @tgt`
-- would silently skip every `redirect IS NULL` row (NULL <> 'x' is NULL, not
-- TRUE) -- the exact bug that shipped 2026-08-16 and 2026-08-17.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-practical-electronics-design-with-arduino-microcontroller.html';

-- Seed the generic variants that may not exist yet on a rebuilt DB.
INSERT INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed, display_in_terms)
SELECT t.q, 1, 1, 0, @tgt, 1, 0
FROM (
            SELECT 'arduino' AS q
  UNION ALL SELECT 'arduino course'
  UNION ALL SELECT 'arduino courses'
  UNION ALL SELECT 'arduino training'
  UNION ALL SELECT 'arduino microcontroller'
  UNION ALL SELECT 'arduino programming'
  UNION ALL SELECT 'learn arduino'
  UNION ALL SELECT 'arduino class'
  UNION ALL SELECT 'arduino classes'
  UNION ALL SELECT 'arduino workshop'
) t
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM (SELECT * FROM catalogsearch_query) q
    WHERE q.store_id = 1 AND TRIM(LOWER(q.query_text)) = t.q
  );

-- Point the generic terms (incl. the observed typo variant) at the course.
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND TRIM(LOWER(query_text)) IN (
    'arduino',
    'arduino course',
    'arduino courses',
    'arduino training',
    'arduino microcontroller',
    'arduino programming',
    'learn arduino',
    'arduino class',
    'arduino classes',
    'arduino workshop',
    'arduino coursre'
  );
