-- 1149: Point AI-for-Network-Security search terms at the WSQ course page
--       (TGS-2024051414), admin-requested 2026-08-29.
--
-- Two CORRECTIONS, not just a fill -- verified against LIVE SG prod 2026-08-29:
--   * 'ai for network security' (the admin's literal query) had an empty redirect.
--   * 'TGS-2024051414' (popularity 24) -- the course's OWN SKU -- pointed at a
--     DIFFERENT course, wsq-pearson-vue-certified-it-specialist-network-security-
--     training.html. So the guard must OVERWRITE, not skip populated rows.
--     NOT (redirect <=> @tgt) is NULL-safe: it fills unset rows AND corrects wrong
--     ones, while no-oping on rows already correct. A bare redirect <> @tgt would
--     silently skip every redirect IS NULL row.
--
-- The pattern is an explicit "AI + network security" term list rather than a bare
-- LIKE, because both obvious keywords are unusable here:
--   * %ai% also matches "Training", "AdversAIrial", "Explainable", etc.
--   * %network security% legitimately belongs to OTHER live courses -- Network
--     Security Essential Training, WSQ Network Securities for Beginners, CompTIA
--     Network+, Pearson VUE IT Specialist. A broad sweep would hijack all of them.
-- The sibling 'ai cyber security' family intentionally points at the AI Security
-- Series category (/ai-security-series.html) and is deliberately left untouched.
--
-- Applied live on SG prod first (search redirects are data, not code); this file
-- exists so a rebuilt/restored DB keeps the state. Partner-safe: TGS- (WSQ)
-- courses exist only on SG, so the store guard no-ops on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @tgt := 'https://www.tertiarycourses.com.sg/wsq-ai-for-network-security.html';

UPDATE catalogsearch_query
SET redirect = @tgt, num_results = 1, is_processed = 1
WHERE @sg = 1
  AND store_id = 1
  AND NOT (redirect <=> @tgt)
  AND ( LOWER(query_text) LIKE '%ai for network security%'
     OR LOWER(query_text) LIKE '%ai in network security%'
     OR LOWER(query_text) LIKE '%ai network security%'
     OR LOWER(query_text) LIKE '%ai for network securities%'
     OR LOWER(query_text) LIKE '%artificial intelligence for network security%'
     OR LOWER(query_text) LIKE '%artificial intelligence in network security%'
     OR LOWER(query_text) LIKE '%tgs-2024051414%' );
