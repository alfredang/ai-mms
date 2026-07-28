-- 823: point "Certified Lean Six Sigma Yellow Belt (CLSSYB)" search terms at the
-- WSQ CLSSYB course page (SG).
--
-- WHY: 13 CLSSYB / "yellow belt" search terms on the SG store all have an EMPTY
-- redirect, so searchers land on a results page instead of the course. The
-- catalog has the WSQ course "WSQ - Certified Lean Six Sigma Yellow Belt
-- (CLSSYB) Training" (SKU TGS-2025053922) at
-- wsq-certified-lean-six-sigma-yellow-belt-clssyb-training.html
-- (verified HTTP 200 on 2026-07-28).
--
-- NOTE: the non-WSQ course C524 "Certified Lean Six Sigma Yellow Belt (CLSSYB)"
-- at certified-lean-six-sigma-yellow-belt.html remains ENABLED and reachable.
-- This migration deliberately consolidates the generic yellow-belt search terms
-- onto the WSQ page; it does NOT retire or 301 the non-WSQ product page.
--
-- SCOPE: explicit exact-term list. Empty-redirect-only guard — an existing
-- intentional redirect is never overwritten. Partner-safe: SG store-code guard,
-- so MY/GH are a no-op (no WSQ/TGS- catalog there). Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-certified-lean-six-sigma-yellow-belt-clssyb-training.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND (redirect IS NULL OR redirect = '')
  AND LOWER(TRIM(query_text)) IN (
    'clssyb',
    'yellow belt',
    'yellow belt six sigma',
    'sigma yellow belt',
    'six sigma yellow belt',
    'lean six sigma yellow belt',
    'certified lean six sigma yellow belt',
    'certified lean six-sigma yellow belt',
    'certified lean six sigma yellow belt (clssyb) training',
    'wsq certified lean six sigma yellow belt',
    'wsq - certified lean six sigma yellow belt',
    'wsq - certified lean six sigma yellow belt (clssyb)',
    'wsq - certified lean six sigma yellow belt (clssyb) training'
  );
