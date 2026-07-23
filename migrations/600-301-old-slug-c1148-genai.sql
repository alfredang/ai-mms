-- 301 redirect from the OLD slug of the course renamed in 599.
--
--   project-management-sme-training-singapore.html
--     -> generative-ai-for-strategic-planning.html
--
-- MUST run AFTER the catalog_url reindex that 599 requires — the reindex
-- regenerates core_url_rewrite and would otherwise clobber this row.
-- Deliberately NOT using INSERT IGNORE (silently no-ops behind an is_system row).
--
-- Store 1 (SG) only. Idempotent.

SET @s := 1;

DELETE FROM core_url_rewrite
WHERE store_id = @s AND is_system = 0
  AND request_path = 'project-management-sme-training-singapore.html';

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT @s, 'rp_c1148_old', 'project-management-sme-training-singapore.html', 'generative-ai-for-strategic-planning.html', 0, 'RP'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1) t WHERE EXISTS (
        SELECT 1 FROM core_url_rewrite c WHERE c.store_id=@s AND c.request_path='project-management-sme-training-singapore.html' AND c.is_system=1));
