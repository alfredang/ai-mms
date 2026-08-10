-- 908 — Search-term redirects: "financial analysis on SME" (and SME/small/medium
-- variants) -> the CASL Financial Analysis for Small and Medium Enterprises course.
--
-- Applied LIVE on SG prod on 2026-08-10 (search redirects are data, not code — a
-- migration alone does not change an already-populated prod row). This file exists
-- so a rebuilt/restored DB keeps the same state.
--
-- Prod state before the fix:
--   * 2 rows empty, incl. the requested term "financial analysis on SME" (+ the
--     "financial analyis on SME" typo variant).
--   * 3 rows pointed at the WRONG course, financial-ratio-analysis.html
--     ("financial analysis SME", "financial analysis with sme",
--      "WSQ - financial analysis for Sme") — an empty-only guard would skip these,
--     so this is a CORRECTION and uses `redirect <> @tgt`.
--   * 1 further row was created between apply and verification and caught on a
--     second pass — hence the LIKE pattern rather than a frozen exact-term list.
--
-- Scope is deliberately narrowed with an SME/small/medium token so the sibling
-- IBF course "Financial Analysis for Non-Finance Managers" is NOT hijacked.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-financial-analysis-for-small-and-medium-enterprises.html';

-- Correction pass: rows with a non-empty but wrong target.
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND redirect <> @tgt
  AND LOWER(query_text) LIKE '%financial analy%'
  AND (LOWER(query_text) LIKE '%sme%'
    OR LOWER(query_text) LIKE '%small%'
    OR LOWER(query_text) LIKE '%medium%');

-- Fill pass: NULL/empty rows (SQL `<>` is unknown against NULL, so these need
-- their own statement).
UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND LOWER(query_text) LIKE '%financial analy%'
  AND (LOWER(query_text) LIKE '%sme%'
    OR LOWER(query_text) LIKE '%small%'
    OR LOWER(query_text) LIKE '%medium%');
