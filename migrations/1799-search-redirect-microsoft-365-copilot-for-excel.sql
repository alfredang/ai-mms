-- Search redirect: "Microsoft 365 Copilot for Excel" + Excel-specific Copilot
-- variants -> the C34 course page.
--
-- On prod, 'copilot excel' pointed at the WSQ M365 Copilot for Organizations
-- course and 'copilot for excel' at Power Apps; both are corrected here.
-- 'copilot excel for finance' is deliberately left alone (ambiguous with the
-- C057 / TGS-2026065050 Copilot for Finance courses).
-- Already applied live on SG prod 2026-10-08. Exact terms only (no LIKE) so a
-- rebuilt DB can't sweep in sibling "copilot" terms. SG guard: target is the
-- SG domain; partner sites must never redirect to it.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/microsoft-365-copilot-for-excel.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(TRIM(query_text)) IN (
    'microsoft 365 copilot for excel',
    'wsq microsoft 365 copilot for excel',
    'copilot for excel',
    'wsq copilot for excel',
    'copilot excel'
  );
