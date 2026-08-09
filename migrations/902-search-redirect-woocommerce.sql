-- Search-term redirect: all WooCommerce search terms -> the CASL Building a
-- Successful eCommerce Store with WooCommerce course product page.
--
-- This is a CORRECTION, not a fill. Before this ran, prod's 21 woocommerce rows
-- pointed at two stale targets, both dead ends:
--   * wordpress-ecommerce-woocommerce.html          -> 301 -> ecommerce-with-wordpress.html -> 404
--     (product C015 "Ecommerce with WordPress" is DISABLED, status = 2)
--   * wsq-building-a-successful-ecommerce-store-with-woocommerce.html
--     -> 301 -> the CASL url below (the WSQ -> CASL rename)
-- Only ONE live WooCommerce course remains: TGS-2026064474. So the broad LIKE is
-- safe here -- there is no sibling course for a generic term to hide.
--
-- The empty-only guard would have been a no-op: 20 of 21 rows were already
-- populated with a wrong target. Hence redirect <> @tgt.
--
-- Applied live on SG prod 2026-08-10 (21 rows); this keeps a rebuilt DB in the same state.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-building-a-successful-ecommerce-store-with-woocommerce.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect <> @tgt)
  AND (LOWER(query_text) LIKE '%woocommerce%' OR LOWER(query_text) LIKE '%woo commerce%');
