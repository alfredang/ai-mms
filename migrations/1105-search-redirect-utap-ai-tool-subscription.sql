-- 1105: search-term redirect -> the NTUC UTAP funding page (utap.html)
--
-- Extends 1103/1104 coverage to AI-tool-subscription phrasings. Applied LIVE on
-- SG prod 2026-08-24 (rows: "utap ai tool subscription" pop=3,
-- "ai tool subscription" pop=1, both previously empty; "utap ai" already
-- correct). This file exists so a rebuilt/restored DB keeps the same state.
--
-- Scope stays TIGHT on purpose: prod carries 25+ "%ai tool(s)%" rows that are
-- COURSE-intent with correct product/category redirects ("ai tools" ->
-- chatgpt-and-generative-ai-courses.html, "Business Innovation with Generative
-- AI Tools" -> its WSQ course, ...). A bare '%ai tool%' would hijack them all.
-- Only 'utap ai%' and the '%ai tool subscription%' phrasing are UTAP-intent.
--
-- NOT (redirect <=> @tgt) is NULL-safe: it fills unset rows AND corrects wrong
-- ones, while no-opping on rows already correct. A bare <> would skip NULLs.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/utap.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
        LOWER(query_text) LIKE 'utap ai%'
     OR LOWER(query_text) LIKE '%ai tool subscription%'
  );
