-- 824: CORRECTION to 823 — force ALL CLSSYB / "yellow belt" search terms to the
-- WSQ course, overwriting wrong existing targets.
--
-- WHY 823 WAS INSUFFICIENT: 823 used an empty-redirect-only guard. On localhost
-- all 13 terms were empty so it looked correct, but on SG PROD 11 of them were
-- ALREADY populated pointing at the NON-WSQ course
-- (certified-lean-six-sigma-yellow-belt.html) — including terms literally
-- containing "WSQ". The guard skipped every one of them, so prod kept sending
-- WSQ searchers to the non-WSQ page. This is the known trap in memories
-- feedback_search_redirect_guard_skips_wrong_targets and
-- feedback_prod_redirects_already_populated_guard_skips.
--
-- Also: new rows appear AFTER a migration ships (searchers keep typing new
-- variants, e.g. 'Certified Lean Six Sigma Yellow Belt (CLSSYB' with an
-- unbalanced paren, created after 823). A fixed exact-term IN() list cannot
-- catch those, so this migration matches by LIKE pattern instead.
--
-- SCOPE: deliberate OVERWRITE (a correction, not a fill). Pattern-matched so it
-- also fixes future typo variants on re-run. Partner-safe: SG store-code guard,
-- MY/GH are a no-op (no WSQ/TGS- catalog there). Idempotent.
--
-- Applied live on SG prod 2026-07-28 (15 rows); this file keeps a rebuilt or
-- restored DB in the same state.
--
-- NOTE: the non-WSQ course C524 remains ENABLED at
-- certified-lean-six-sigma-yellow-belt.html — it is simply no longer the search
-- destination for these terms.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-certified-lean-six-sigma-yellow-belt-clssyb-training.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND redirect <> @tgt
  AND (
        LOWER(query_text) LIKE '%clssyb%'
     OR LOWER(query_text) LIKE '%yellow belt%'
     OR LOWER(query_text) LIKE '%yello belt%'
     OR LOWER(query_text) LIKE '%yellow-belt%'
  );
