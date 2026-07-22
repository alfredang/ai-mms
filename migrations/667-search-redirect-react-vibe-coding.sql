-- 667: search-term redirects for "react vibe coding" intent (SG).
--
-- WHY: searching "react vibe coding" (and sibling terms carrying the same
-- intent, including the course's own title) returned a results page instead
-- of landing on the canonical funded course. One older row already redirected
-- but through a stale 301 chain (wsq-react-ui-course.html -> canonical).
--
-- WHAT: point these EXACT terms at TGS course "WSQ - Build Full Stack React
-- Web App with Vibe Coding" at
-- wsq-build-full-stack-react-web-app-with-vibe-coding.html (verified HTTP 200,
-- no redirect chain, 2026-07-22).
--
-- SCOPE: explicit term list, not a LIKE sweep. The one existing redirect
-- being overwritten (the course-title row) already pointed at this same
-- course via a 301 chain -- this normalises it to the direct URL.
--
-- Partner-safe: SG store-code guard, so MY/GH are a no-op. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-build-full-stack-react-web-app-with-vibe-coding.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND LOWER(TRIM(query_text)) IN (
    'react vibe coding',
    'react full stack vibe',
    'ai vibe coding for react',
    'build full stack react web app with vibe coding',
    'wsq - build full stack react web app with vibe coding',
    'day 2 - wsq - build full stack react web app with vibe coding'
  );
