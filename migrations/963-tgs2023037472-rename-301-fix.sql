-- 963: Follow-up to 943 -- land the 301s for the TGS-2023037472 repurpose.
--
-- Why a separate file: 943 is already in the schema_migrations ledger locally,
-- and edited migrations never re-run on prod
-- ([[feedback_edited_shared_migrations_never_rerun_on_prod]]). 943's
-- INSERT IGNORE for the 301 silently no-opped because the old request_path was
-- still held by the is_system = 1 product rewrite (row 2951161), and 943 only
-- DELETEd is_system = 0 squatters. INSERT IGNORE swallowed the duplicate-key
-- error ([[feedback_insert_ignore_swallows_rewrite_301s]]).
--
-- Two paths must 301 to the new slug, not one:
--   a) wsq-digital-transformation-...-generative-ai-genai.html  (the slug 943 renamed away from)
--   b) wsq-digital-transformation-...-generative-ai-gai.html    (pre-existing RP row that
--      pointed at (a); left alone it becomes a 301 -> 301 chain)
-- Anchored on this course's FULL old filenames -- never a shared stem -- so the
-- sibling TGS-2020503395 (wsq-business-innovation-with-ai-agents) is untouched.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => no-op.
-- Idempotent: DELETE-then-INSERT converges on re-run.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037472' LIMIT 1);

SET @old_genai := 'wsq-digital-transformation-and-business-innovation-with-generative-ai-genai.html';
SET @old_gai   := 'wsq-digital-transformation-and-business-innovation-with-generative-ai-gai.html';
SET @new_path  := 'wsq-business-innovation-with-agentic-ai-and-ai-agents.html';

-- Clear the stale rows on BOTH old paths, whatever their is_system flag. The
-- is_system = 1 row for the old slug is dead weight now: the URL Rewrites
-- indexer regenerates the product's system rewrite at the NEW url_key (943
-- deleted url_path at every scope to force exactly that).
DELETE FROM core_url_rewrite
 WHERE request_path IN (@old_genai, @old_gai)
   AND @e IS NOT NULL;

-- (a) old -genai slug -> new slug, permanent.
INSERT INTO core_url_rewrite
       (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, CONCAT('product/', @e, '/rename943-genai'), @old_genai, @new_path,
       0, 'RP', 'TGS-2023037472 repurpose 943'
  FROM DUAL WHERE @e IS NOT NULL;

-- (b) legacy -gai slug -> new slug directly, collapsing the 301 chain.
INSERT INTO core_url_rewrite
       (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT 1, CONCAT('product/', @e, '/rename943-gai'), @old_gai, @new_path,
       0, 'RP', 'TGS-2023037472 repurpose 943'
  FROM DUAL WHERE @e IS NOT NULL;
