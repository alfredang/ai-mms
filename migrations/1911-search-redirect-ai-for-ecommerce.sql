-- Search "ai for ecommerce" (and the "ai e-commerce" / "ai for e-commerce" variants)
-- -> WSQ AI for eCommerce course (TGS-2026064474) instead of the ai-for-retail category.
-- Already applied LIVE on SG prod 2026-11-08; this keeps a rebuilt DB in the same state.
-- SG-only; NULL-safe guard overwrites the old category redirect and fills empty rows.
-- Match on the term with spaces/hyphens stripped so only these exact phrasings are hit.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-ai-for-ecommerce.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND REPLACE(REPLACE(LOWER(TRIM(query_text)), '-', ''), ' ', '') IN ('aiforecommerce', 'aiecommerce');
