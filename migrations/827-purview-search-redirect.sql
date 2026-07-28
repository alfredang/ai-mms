-- 827: redirect on-site searches containing "purview" to the WSQ SC-400 course
-- (Administering Information Protection and Compliance in Microsoft 365).
-- Applied live on SG prod 2026-07-29; this keeps a rebuilt/restored DB in sync.
-- SG-only guard: WSQ course exists only on the Singapore site.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-administering-information-protection-and-compliance-in-microsoft-365-sc-400.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(query_text) LIKE '%purview%'
  AND (redirect IS NULL OR redirect = '' OR redirect <> @tgt);
