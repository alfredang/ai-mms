-- Search-term redirect: "raspberry pi essential training" (+ all %raspberry%essential%
-- variants, except IoT ones) -> WSQ Mastering Raspberry Pi for Beginners.
-- Old target raspberry-pi-essential-training-... now 301s to iot-with-raspberry-pi.html.
-- Applied live on SG prod 2026-10-05. NULL-safe guard overwrites the stale target. SG-only.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-mastering-raspberry-pi-hands-on-practical-applications-for-beginners.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%raspberry%essential%'
  AND LOWER(query_text) NOT LIKE '%iot%';
