-- 301 redirects from the OLD slugs of the four courses repurposed in 646.
--
--   agentic-ai-with-claude-code.html           -> claude-cowork-masterclass.html
--   claude-cowork-for-business-automation.html -> claude-code-masterclass.html
--   claude-ai-for-excel-data-analysis.html     -> claude-design-masterclass.html
--   claude-for-microsoft-365.html              -> claude-microsoft-365-masterclass.html
--
-- Written for EVERY live store on the instance (SG store 1, MY store 2,
-- GH store 3 — resolved from core_store, so the same file is partner-safe;
-- GH's parity-imported catalog lacks rewrite history and does NOT auto-301).
--
-- Deliberately NOT using INSERT IGNORE: a product may still own the old
-- request_path via an is_system=1 row (until the catalog_url reindex runs),
-- in which case IGNORE silently no-ops and the 301 never ships. We DELETE any
-- non-system squatter on the old path first, then insert guarded against a
-- surviving system row. After the post-deploy catalog_url reindex, re-check
-- each old URL returns 301 on every site and re-apply if the reindex
-- clobbered a row. Idempotent.

DELETE FROM core_url_rewrite
WHERE is_system = 0
  AND request_path IN (
    'agentic-ai-with-claude-code.html',
    'claude-cowork-for-business-automation.html',
    'claude-ai-for-excel-data-analysis.html',
    'claude-for-microsoft-365.html');

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_c1382_old_', s.store_id), 'agentic-ai-with-claude-code.html', 'claude-cowork-masterclass.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite c WHERE c.store_id = s.store_id AND c.request_path = 'agentic-ai-with-claude-code.html' AND c.is_system = 1);

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_c1417_old_', s.store_id), 'claude-cowork-for-business-automation.html', 'claude-code-masterclass.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite c WHERE c.store_id = s.store_id AND c.request_path = 'claude-cowork-for-business-automation.html' AND c.is_system = 1);

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_c201_old_', s.store_id), 'claude-ai-for-excel-data-analysis.html', 'claude-design-masterclass.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite c WHERE c.store_id = s.store_id AND c.request_path = 'claude-ai-for-excel-data-analysis.html' AND c.is_system = 1);

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('rp_c197_old_', s.store_id), 'claude-for-microsoft-365.html', 'claude-microsoft-365-masterclass.html', 0, 'RP'
FROM core_store s
WHERE s.store_id > 0
  AND NOT EXISTS (SELECT 1 FROM core_url_rewrite c WHERE c.store_id = s.store_id AND c.request_path = 'claude-for-microsoft-365.html' AND c.is_system = 1);
