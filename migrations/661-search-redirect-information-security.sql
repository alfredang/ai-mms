-- 661: search-term redirect "information security" -> WSQ Information Security
-- Management and Compliance Frameworks course (SG).
--
-- WHY: user directive -- searches for "information security" should land on the
-- canonical funded course that teaches it, rather than a generic result page.
--
-- WHAT: point the EXACT term 'information security' (case/space-insensitive) at
-- wsq-information-security-management-and-compliance-frameworks.html (HTTP 200
-- verified on prod). INSERT the row if a live search never created it yet, then
-- UPDATE so it works whether or not the catalogsearch_query row already exists.
--
-- SCOPE: one explicit term, not a LIKE sweep. Set unconditionally for that term
-- (per user directive) rather than empty-guarded, so a pre-existing wrong
-- redirect is corrected too.
--
-- Partner-safe: SG store-code guard, so MY/GH are a no-op. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-information-security-management-and-compliance-frameworks.html';

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'information security', 1, 1, 0, @tgt, 1
FROM dual
WHERE @sg = 1
  AND NOT EXISTS (
    SELECT 1 FROM catalogsearch_query
    WHERE store_id = 1 AND LOWER(TRIM(query_text)) = 'information security'
  );

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(TRIM(query_text)) = 'information security';
