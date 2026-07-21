-- 653: Search-term redirect (SG only) — "openclaw" and variations ->
--      the WSQ Business Transformation with OpenClaw and NFT course page.
--
-- SG-gated: the absolute .com.sg target must never be written on a partner DB
-- (store_id=1 / code='singapore' exists only on SG). Idempotent via INSERT IGNORE
-- (creates the query rows if a term was never searched) + a scoped UPDATE that
-- overwrites an empty OR wrong redirect but no-ops once it already points here.
-- See memory feedback_search_redirect_guard_skips_wrong_targets: an empty-only
-- guard would silently skip a term that already points somewhere wrong, so we
-- key the UPDATE off "not already the target" instead of "redirect empty".

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @url := 'https://www.tertiarycourses.com.sg/wsq-business-transformation-with-openclaw-and-nft.html';

INSERT IGNORE INTO catalogsearch_query (query_text, num_results, popularity, redirect, store_id, display_in_terms, is_active, is_processed)
SELECT t.q, 0, 0, @url, 1, 0, 1, 1
FROM (
  SELECT 'openclaw' AS q UNION ALL
  SELECT 'open claw' UNION ALL
  SELECT 'openclaw nft' UNION ALL
  SELECT 'openclaw course' UNION ALL
  SELECT 'openclaw training' UNION ALL
  SELECT 'open claw nft' UNION ALL
  SELECT 'openclaw ai' UNION ALL
  SELECT 'open claw ai' UNION ALL
  SELECT 'openclaw and nft' UNION ALL
  SELECT 'business transformation openclaw'
) t
WHERE @sg = 1;

-- Point every openclaw variant (existing or just-inserted) at the course, unless
-- it already does. Overwrites a wrong prior redirect; idempotent on re-run.
UPDATE catalogsearch_query
SET redirect = @url
WHERE @sg = 1
  AND store_id = 1
  AND query_text LIKE '%openclaw%'
  AND (redirect IS NULL OR redirect <> @url);

UPDATE catalogsearch_query
SET redirect = @url
WHERE @sg = 1
  AND store_id = 1
  AND query_text LIKE '%open claw%'
  AND (redirect IS NULL OR redirect <> @url);
