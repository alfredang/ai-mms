-- Search-term redirect: AI-agent-security terms -> WSQ AI Security for
-- Autonomous AI Agents (SG only).
--
-- Applied live on SG prod 2026-08-17; this file exists so a rebuilt/restored DB
-- keeps the state.
--
-- DELIBERATELY NARROW PATTERNS. The %ai%security% keyword space on SG prod is
-- densely populated with other INTENTIONAL redirects that must NOT be clobbered:
--   * ~30 rows  -> ai-security-series.html (category page + a typo cluster:
--                  "ai cybber security", "ai yber security", ...)
--   * ~8 rows   -> wsq-build-a-human-ai-workforce-with-autonomous-ai-agents.html
--                  (a DIFFERENT WSQ autonomous-agents course)
--   * many      -> CompTIA Security+ / CySA+ / SecurityX / CISSP / SC-100 /
--                  network-security course pages
-- A broad '%ai%security%' or '%autonomous%' LIKE would repoint all of the above
-- at this course. Match only the specific requested phrasings.
--
-- NOT (redirect <=> @tgt) is NULL-safe -- a plain `redirect <> @tgt` silently
-- skips rows whose redirect IS NULL, which is exactly what needs fixing.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-security-for-autonomous-ai-agents.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND (
        LOWER(TRIM(query_text)) LIKE 'ai security for ai agent%'
     OR LOWER(TRIM(query_text)) LIKE 'ai security on ai agent%'
     OR LOWER(TRIM(query_text)) LIKE '%ai security for autonomous ai agent%'
     OR LOWER(TRIM(query_text)) LIKE 'ai agent security%'
     OR LOWER(TRIM(query_text)) LIKE 'ai agents security%'
  );

-- "ai agent security" / "ai agents security" had no row at all on prod
-- (never searched), so an UPDATE alone would not create the redirect.
INSERT IGNORE INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'ai agent security', 1, 1, 1, @tgt, 1 FROM DUAL WHERE @sg = 1;

INSERT IGNORE INTO catalogsearch_query
  (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT 'ai agents security', 1, 1, 1, @tgt, 1 FROM DUAL WHERE @sg = 1;
