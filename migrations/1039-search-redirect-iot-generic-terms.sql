-- 1039: Point generic IoT search terms at the IoT training course page.
--
-- Applied live on SG prod first (search redirects are data, not code); this file
-- exists so a rebuilt/restored DB keeps the same state.
--
-- Scope is deliberately an exact-term IN() list, NOT LIKE '%iot%'. On prod 285
-- rows match that pattern and 169 of them already carry correct, MORE SPECIFIC
-- redirects (e.g. 'wsq iot' -> the WSQ Fundamentals course, 'IoT Training with
-- ESP8266 Wi-Fi Controller' -> the ESP8266 course). A broad overwrite would
-- regress every one of those, and would also catch false positives such as
-- 'biotechnology' and 'Node-Red for iOT'.
--
-- The bare term 'iot' (query_id 36, popularity 1578) was ALREADY correct and is
-- included only so a rebuilt DB reproduces it.
--
-- Guard note: uses NOT (redirect <=> @tgt), the NULL-safe inequality. A plain
-- `redirect <> @tgt` evaluates to NULL for rows where redirect IS NULL and so
-- silently skips exactly the empty rows this migration needs to fill -- that is
-- what happened on the first live attempt here (0 rows updated).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/internet-of-things-iot-training-in.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) IN (
    'iot',
    'internet of things',
    'internet-of-things',
    'iot training',
    'iot trainings'
  );
