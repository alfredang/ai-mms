-- 1561: flatten the redirect chains behind GSC "Duplicate, Google chose
-- different canonical than user" (2026-09-26, 19 URLs on the SG property).
--
-- WHY: 18 of the 19 flagged URLs are intentional 301s from retired/repurposed
-- course slugs. Five of them were TWO-hop chains, and prod held 1,056 such
-- chains in total (548 distinct middle hops) that accumulated since 1086 ran
-- (every repurpose since then re-pointed old slugs at a slug that was later
-- itself retired). Examples still live today:
--   html5-css3-training-courses-singapore.html
--     -> manage-multi-agents-with-paperclip.html
--     -> build-one-person-company-with-multi-ai-agents.html
--   certified-kubernetes-application-developer-ckad-training-{971,1176,1177,1206}.html
--     -> certified-kubernetes-application-developer-ckad-training-1219.html   (411 rows)
--     -> certified-kubernetes-application-developer-ckad-training.html
--
-- Same statement shape as 1086 (join hops ACROSS store scopes, derived table to
-- avoid ERROR 1093) with two differences learned on prod today:
--   * TWO passes are NOT enough. The category collision-suffix ladders
--     (aws-certification-exams-5 -> -9 -> -13 -> ...) are up to ~40 hops deep;
--     on prod the pass changed 1056, 513, 503, 483, 443, 363, 203, then 0 rows.
--     Each pass halves the remaining depth, so the pass is repeated 8 times
--     here (apply.php runs plain SQL -- no loops); every extra pass is a no-op.
--   * `hop.next_target <> a.request_path` guards against writing a self-loop
--     (a 2-cycle A->B->A would otherwise become A->A = redirect loop).
-- Redirects are data: this was applied live on SG prod first (2026-09-26); the
-- file keeps a rebuilt DB in the same state. Idempotent; partner-safe (acts only
-- on locally-chained rows).

SET SESSION group_concat_max_len = 65535;

-- pass 1 of 8 (each pass halves the remaining chain depth; no-op once flat)
UPDATE core_url_rewrite a
JOIN (
    SELECT request_path,
           SUBSTRING_INDEX(GROUP_CONCAT(target_path ORDER BY (store_id = 0) DESC, store_id SEPARATOR 0x1F), 0x1F, 1) AS next_target
      FROM core_url_rewrite
     WHERE options IN ('R','RP')
     GROUP BY request_path
) hop ON hop.request_path = a.target_path
SET a.target_path = hop.next_target
WHERE a.options IN ('R','RP')
  AND hop.next_target NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> hop.next_target
  AND hop.next_target <> a.request_path;

-- pass 2 of 8 (each pass halves the remaining chain depth; no-op once flat)
UPDATE core_url_rewrite a
JOIN (
    SELECT request_path,
           SUBSTRING_INDEX(GROUP_CONCAT(target_path ORDER BY (store_id = 0) DESC, store_id SEPARATOR 0x1F), 0x1F, 1) AS next_target
      FROM core_url_rewrite
     WHERE options IN ('R','RP')
     GROUP BY request_path
) hop ON hop.request_path = a.target_path
SET a.target_path = hop.next_target
WHERE a.options IN ('R','RP')
  AND hop.next_target NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> hop.next_target
  AND hop.next_target <> a.request_path;

-- pass 3 of 8 (each pass halves the remaining chain depth; no-op once flat)
UPDATE core_url_rewrite a
JOIN (
    SELECT request_path,
           SUBSTRING_INDEX(GROUP_CONCAT(target_path ORDER BY (store_id = 0) DESC, store_id SEPARATOR 0x1F), 0x1F, 1) AS next_target
      FROM core_url_rewrite
     WHERE options IN ('R','RP')
     GROUP BY request_path
) hop ON hop.request_path = a.target_path
SET a.target_path = hop.next_target
WHERE a.options IN ('R','RP')
  AND hop.next_target NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> hop.next_target
  AND hop.next_target <> a.request_path;

-- pass 4 of 8 (each pass halves the remaining chain depth; no-op once flat)
UPDATE core_url_rewrite a
JOIN (
    SELECT request_path,
           SUBSTRING_INDEX(GROUP_CONCAT(target_path ORDER BY (store_id = 0) DESC, store_id SEPARATOR 0x1F), 0x1F, 1) AS next_target
      FROM core_url_rewrite
     WHERE options IN ('R','RP')
     GROUP BY request_path
) hop ON hop.request_path = a.target_path
SET a.target_path = hop.next_target
WHERE a.options IN ('R','RP')
  AND hop.next_target NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> hop.next_target
  AND hop.next_target <> a.request_path;

-- pass 5 of 8 (each pass halves the remaining chain depth; no-op once flat)
UPDATE core_url_rewrite a
JOIN (
    SELECT request_path,
           SUBSTRING_INDEX(GROUP_CONCAT(target_path ORDER BY (store_id = 0) DESC, store_id SEPARATOR 0x1F), 0x1F, 1) AS next_target
      FROM core_url_rewrite
     WHERE options IN ('R','RP')
     GROUP BY request_path
) hop ON hop.request_path = a.target_path
SET a.target_path = hop.next_target
WHERE a.options IN ('R','RP')
  AND hop.next_target NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> hop.next_target
  AND hop.next_target <> a.request_path;

-- pass 6 of 8 (each pass halves the remaining chain depth; no-op once flat)
UPDATE core_url_rewrite a
JOIN (
    SELECT request_path,
           SUBSTRING_INDEX(GROUP_CONCAT(target_path ORDER BY (store_id = 0) DESC, store_id SEPARATOR 0x1F), 0x1F, 1) AS next_target
      FROM core_url_rewrite
     WHERE options IN ('R','RP')
     GROUP BY request_path
) hop ON hop.request_path = a.target_path
SET a.target_path = hop.next_target
WHERE a.options IN ('R','RP')
  AND hop.next_target NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> hop.next_target
  AND hop.next_target <> a.request_path;

-- pass 7 of 8 (each pass halves the remaining chain depth; no-op once flat)
UPDATE core_url_rewrite a
JOIN (
    SELECT request_path,
           SUBSTRING_INDEX(GROUP_CONCAT(target_path ORDER BY (store_id = 0) DESC, store_id SEPARATOR 0x1F), 0x1F, 1) AS next_target
      FROM core_url_rewrite
     WHERE options IN ('R','RP')
     GROUP BY request_path
) hop ON hop.request_path = a.target_path
SET a.target_path = hop.next_target
WHERE a.options IN ('R','RP')
  AND hop.next_target NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> hop.next_target
  AND hop.next_target <> a.request_path;

-- pass 8 of 8 (each pass halves the remaining chain depth; no-op once flat)
UPDATE core_url_rewrite a
JOIN (
    SELECT request_path,
           SUBSTRING_INDEX(GROUP_CONCAT(target_path ORDER BY (store_id = 0) DESC, store_id SEPARATOR 0x1F), 0x1F, 1) AS next_target
      FROM core_url_rewrite
     WHERE options IN ('R','RP')
     GROUP BY request_path
) hop ON hop.request_path = a.target_path
SET a.target_path = hop.next_target
WHERE a.options IN ('R','RP')
  AND hop.next_target NOT LIKE 'catalog/category/view/id/%'
  AND a.target_path <> hop.next_target
  AND hop.next_target <> a.request_path;

