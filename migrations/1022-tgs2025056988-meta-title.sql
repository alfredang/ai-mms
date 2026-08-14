-- 1022: TGS-2025056988 "WSQ - Agentic AI for Digital Marketing" -- meta_title only.
--
-- Follow-up to 1020. The meta_title statement was added to 1020 AFTER that file had
-- already been picked up and ledgered by a concurrently-running apply.php (applied_at
-- 2026-08-14 13:52:37), so the edit never executed and never will -- an already-ledgered
-- migration is never re-run. [[feedback_edited_shared_migrations_never_rerun_on_prod]]
-- This separate NNN+1 file is the correct vehicle.
-- [[feedback_amended_migration_needs_followup_file]]
--
-- The stored value is "WSQ Formulate Digital Marketing Strategy with AI Research & ROI
-- Analysis | Tertiary Courses Singapore" -- stale on two counts:
--   1. It names "Formulate Digital Marketing Strategy with AI Agent and Deep Research",
--      a title this course no longer carries (it is now "Agentic AI for Digital
--      Marketing"), and the AI-Research/ROI framing that 1020 retired.
--   2. It bakes in the "| Tertiary Courses Singapore" brand suffix that
--      MMD_Seotitle_Block_Html_Head::_applyBrandSuffix() appends at RENDER time
--      (app/code/local/MMD/Seotitle/Block/Html/Head.php). The same block prepends
--      "WSQ funded" for TGS- SKUs on SG via _applyFundingPrefix(). Both transforms are
--      idempotent, so a baked-in suffix does not currently double up -- but it hardcodes
--      the SG brand into a stored value the composer is meant to own.
--
-- So store the bare title BODY only, with neither affix, and let the block compose.
--
-- Everything else 1020 changed (description + LSN_DATA, short_description,
-- learning_outcomes cms_block, meta_description, meta_keyword) applied correctly and is
-- NOT re-touched here. name, url_key, categories, whoshouldattend, prerequisite,
-- trainerprofile, skills_framework and funding_and_grant remain untouched -- this was a
-- content update, not a rename or a repurpose.
--
-- Partner-safe: TGS- SKUs exist only on SG => @e IS NULL on MY/GH => guarded no-op.
-- Pure ASCII. Idempotent -- re-runnable.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2025056988' LIMIT 1);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, 82, 0, @e,
'Agentic AI for Digital Marketing with Claude Cowork, MCP and Custom Skills'
FROM dual WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Drop any store-scoped override so the store 0 value is what renders.
DELETE FROM catalog_product_entity_varchar
WHERE entity_id = @e AND attribute_id = 82 AND store_id <> 0 AND @e IS NOT NULL;
