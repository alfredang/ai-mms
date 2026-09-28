-- Search redirects requested 2026-09-28. Applied live on SG prod the same
-- day; this keeps a rebuilt DB in sync.
--
--   shopify  -> CASL - AI for Shopify eCommerce Store (TGS-2026064175)
--     Every search term containing "shopify" (31 rows on prod, incl. the
--     pop-1087 "Shopify" row that pointed at the Shopify category page,
--     retired in 1591). The other old targets (shopify-online-shop-training,
--     casl-build-your-own-ecommerce-store-with-ai-vibe-coding) already 301
--     to this course -- pointing straight at it drops the extra hop. It is
--     the only live Shopify course on SG.
--
--   retail   -> AI for Retail category page
--     "retail" (+ tight variants: ai retail, ai for retail, retail courses,
--     retail training). Prod's "retail" row pointed at an unrelated
--     affiliate-marketing course. Long course-title queries that merely
--     mention retail are left alone.
--
-- NULL-safe NOT (redirect <=> @tgt) fills empty rows AND overwrites wrong
-- ones. SG-only guard.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

SET @tgt := 'https://www.tertiarycourses.com.sg/casl-ai-for-shopify-ecommerce-store.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (LOWER(query_text) LIKE '%shopify%' OR LOWER(query_text) LIKE '%shpify%');

SET @tgt := 'https://www.tertiarycourses.com.sg/ai-for-retail-courses.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) REGEXP '^(ai )?(for )?retail( courses?| training)?$';
