-- Point Autodesk Inventor search variants at the WSQ Product Design with Autodesk Inventor course.
-- Both sibling Inventor courses are retired (C168 "Autodesk Inventor Essential Training" and
-- C774 ACP Inventor Mechanical Design, both status = 2), so TGS-2021006715 is the only live
-- Inventor course. Rows previously pointed at autodesk-inventor-training.html and at
-- wsq-autodesk-certified-professional-acp-for-inventor-mechanical-design.html -- the latter
-- 301-chains into wsq-generative-ai-for-3d-modeling.html, an unrelated course.
--
-- Exclusions are load-bearing: "App Inventor" / "Apps Inventor" / MIT / Android terms belong to
-- the Android apps development course, and "%inventory%" terms are supply-chain / Xero / warehouse.
-- Keep every NOT LIKE below when copying this file.
--
-- SG-only (store_id = 1); no-op on partner sites where the WSQ course does not exist.
-- NULL-safe guard: fills unset rows AND overwrites wrong ones, no-ops on already-correct.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-product-design-with-autodesk-inventor.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%inventor%'
  AND LOWER(query_text) NOT LIKE '%inventory%'
  AND LOWER(query_text) NOT LIKE '%app inventor%'
  AND LOWER(query_text) NOT LIKE '%apps inventor%'
  AND LOWER(query_text) NOT LIKE '%android%'
  AND LOWER(query_text) NOT LIKE '%mit %'
  AND LOWER(query_text) NOT LIKE '%non-programmer%';
