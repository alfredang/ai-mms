-- Search "sales" -> WSQ Closing Sales with Empathy-Driven People-Focused Selling (TGS-2025052342).
-- Was redirecting to finance-courses.html. Also fills two empty on-topic variants.
-- Exact-term match only: "sales" is generic (LIKE '%sales%' would sweep salesforce etc.).
-- "sale" (-> ecommerce-training-courses.html) is intentionally left alone.
-- Applied live on SG prod 2026-10-20. SG-only (WSQ course).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-closing-sales-with-empathy-driven-people-focused-selling.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) IN ('sales', 'closing sales empathy', 'empathy selling');
