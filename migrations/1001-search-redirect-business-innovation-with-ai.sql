-- 1001: point "business innovation with AI" search terms at the CASL - Business
-- Innovation with Artificial Intelligence course (TGS-2026064716).
--
-- Applied live on SG prod 2026-08-14 (search redirects are data, not code, so the
-- migration alone does not change an already-populated prod row). This file exists so a
-- rebuilt/restored DB keeps the same state. Live run reported "rows updated: 5":
-- four rows that wrongly pointed at the GenAI course
--   ("business innovation with ai tools", "ai for business innovation",
--    "wsq business innovation with ai", "business innovation woth  ai")
-- plus one empty row ("business innovation with artifi"). The other 26 matching rows
-- were already on target and were skipped by the idempotency guard.
--
-- NULL-safe guard: `redirect <> @tgt` evaluates to NULL — not TRUE — for rows where
-- redirect IS NULL, so it would silently skip exactly the empty rows a fill must cover.
-- `NOT (redirect <=> @tgt)` is the correct comparison and doubles as the idempotency
-- guard (rows already on target are excluded, so re-runs are no-ops).
--
-- SCOPING — this is the important part of this migration. "business innovation with X"
-- is a crowded family on SG: at least six distinct live courses share the prefix
--   - AI                 -> casl-business-innovation-with-artificial-intelligence.html  (this target)
--   - AI Agents          -> wsq-business-innovation-with-ai-agents.html
--   - Generative AI      -> wsq-digital-transformation-and-business-innovation-with-generative-ai-genai.html
--   - Blockchain         -> wsq-business-innovation-with-ai-agents.html
--   - IoT                -> casl-business-innovation-with-internet-of-things-iot.html
--   - Metaverse          -> wsq-business-innovation-with-metaverse-and-immersive-technologies.html
--   - OpenClaw / NFT     -> wsq-business-transformation-with-openclaw-and-nft.html
-- A bare '%business innovation%' pattern would have hijacked ALL of them. The WHERE
-- clause below therefore requires an AI/artificial-intelligence token AND excludes every
-- sibling subject by name. The exclusions are load-bearing — do not "simplify" them.
--
-- The `ai` match uses a REGEXP word-boundary test so it hits "business innovation ai" and
-- "business innovation with AI" but not "gai"/"genai" substrings (which are excluded
-- explicitly anyway, belt and braces).

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/casl-business-innovation-with-artificial-intelligence.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND LOWER(query_text) LIKE '%business innovation%'
  AND (
        LOWER(query_text) LIKE '%artificial%'
     OR LOWER(query_text) LIKE '%artifi%'
     OR LOWER(query_text) LIKE '%artific%'
     OR LOWER(query_text) LIKE '%intellig%'
     OR LOWER(query_text) LIKE '%intellign%'
     OR LOWER(query_text) REGEXP '(^|[^a-z])ai([^a-z]|$)'
  )
  AND LOWER(query_text) NOT LIKE '%blockchain%'
  AND LOWER(query_text) NOT LIKE '%block chain%'
  AND LOWER(query_text) NOT LIKE '%iot%'
  AND LOWER(query_text) NOT LIKE '%internet%'
  AND LOWER(query_text) NOT LIKE '%metaverse%'
  AND LOWER(query_text) NOT LIKE '%immersive%'
  AND LOWER(query_text) NOT LIKE '%additive%'
  AND LOWER(query_text) NOT LIKE '%openclaw%'
  AND LOWER(query_text) NOT LIKE '%nft%'
  AND LOWER(query_text) NOT LIKE '%bitcoin%'
  AND LOWER(query_text) NOT LIKE '%generative%'
  AND LOWER(query_text) NOT LIKE '%genai%'
  AND LOWER(query_text) NOT LIKE '%gen ai%'
  AND LOWER(query_text) NOT LIKE '%gai%'
  AND LOWER(query_text) NOT LIKE '%agent%'
  AND LOWER(query_text) NOT LIKE '%fujifilm%';

-- Seed the canonical phrasings so a rebuilt DB redirects them even before a real searcher
-- creates the row.
--
-- NOTE: catalogsearch_query has NO unique key on (query_text, store_id) — verified on both
-- localhost and SG prod 2026-08-14, where the only unique index is PRIMARY (query_id).
-- INSERT IGNORE / ON DUPLICATE KEY therefore never fire here and would append a DUPLICATE
-- row on every run (same failure mode as cms_block.identifier). Each seed is guarded with
-- a NOT EXISTS subselect instead, which is what actually makes this idempotent.
INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT * FROM (SELECT 'business innovation with AI' AS q, 1 AS s, 1 AS n, 1 AS p, @tgt AS r, 1 AS i) t
WHERE @sg = 1 AND NOT EXISTS (
  SELECT 1 FROM catalogsearch_query c WHERE c.store_id = 1 AND c.query_text = 'business innovation with AI');

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT * FROM (SELECT 'Business Innovation with Artificial Intelligence' AS q, 1 AS s, 1 AS n, 1 AS p, @tgt AS r, 1 AS i) t
WHERE @sg = 1 AND NOT EXISTS (
  SELECT 1 FROM catalogsearch_query c WHERE c.store_id = 1 AND c.query_text = 'Business Innovation with Artificial Intelligence');

INSERT INTO catalogsearch_query (query_text, store_id, num_results, popularity, redirect, is_processed)
SELECT * FROM (SELECT 'CASL - Business Innovation with Artificial Intelligence' AS q, 1 AS s, 1 AS n, 1 AS p, @tgt AS r, 1 AS i) t
WHERE @sg = 1 AND NOT EXISTS (
  SELECT 1 FROM catalogsearch_query c WHERE c.store_id = 1 AND c.query_text = 'CASL - Business Innovation with Artificial Intelligence');
