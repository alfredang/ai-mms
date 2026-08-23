-- 1086: follow-up to 1085 — flatten redirect chains that cross store scopes.
--
-- WHY: 1085 flattened chains using `b.store_id = a.store_id`. That JOIN missed
-- chains whose two hops live in DIFFERENT scopes, which live traffic still
-- follows because Magento falls back from the store row to the store_id=0
-- (default) row. Both of these still served two 301s after 1085 deployed:
--   augmented-reality-ar-vr-training.html -> wsq-develop-augmented-reality-ar-
--     applications.html -> wsq-ai-vibe-coding-for-augmented-reality-ar-applications.html
--   google-tag-manager-courses.html -> wsq-mastering-google-tag-manager-... ->
--     wsq-claude-cowork-for-digital-marketing.html
--
-- 1085 is already in the ledger and must never be edited (an edited applied
-- migration never re-runs on prod), hence this follow-up file.
--
-- Scope note: store_id=2 rows are orphans from a retired store (core_store has
-- only admin=0 and singapore=1), so they never serve traffic; they are included
-- for consistency and to stop a future store-id reuse resurrecting a chain.
--
-- NOT handled here (deliberately): 41 rewrites whose target is a DISABLED
-- category (`catalog/category/view/id/N`, is_active=0). Those already return a
-- plain 404 with no redirect hop, so they belong to the GSC "Not found (404)"
-- bucket, not "Page with redirect". Deleting the rows would not change the
-- status code. Left for a separate, deliberate decision (restore vs retire).
--
-- Idempotent + set-based; partner-safe (acts only on locally-chained rows).

SET SESSION group_concat_max_len = 65535;

-- Resolve each redirect target to ONE winning next-hop first (materialised in a
-- derived table, which MySQL 5.7/8 allows to reference core_url_rewrite while we
-- update it -- a correlated subquery on the update target raises ERROR 1093).
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
  AND a.target_path <> hop.next_target;

-- Second pass: when two chains SHARE a middle hop, flattening the shared hop in
-- pass 1 can leave one more level (A -> B -> C where B was itself rewritten in
-- the same statement). One more pass settles it; no-op once clean.
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
  AND a.target_path <> hop.next_target;
