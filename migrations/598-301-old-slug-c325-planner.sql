-- 301 redirect from the OLD slug of the course renamed in 597.
--
--   microsoft-project-training.html -> microsoft-planner-masterclass.html
--
-- MUST run AFTER the catalog_url reindex that 597 requires — the reindex
-- regenerates core_url_rewrite and would otherwise clobber this row.
-- (memory: catalog_url reindex regenerates 301s)
--
-- Deliberately NOT using INSERT IGNORE — an is_system row owning the path would
-- make IGNORE silently no-op and the 301 would never ship.
-- (memory: INSERT IGNORE into core_url_rewrite silently no-ops)
--
-- Store 1 (SG) only. Idempotent.

SET @s := 1;

DELETE FROM core_url_rewrite
WHERE store_id = @s AND is_system = 0
  AND request_path = 'microsoft-project-training.html';

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT @s, 'rp_c325_old', 'microsoft-project-training.html', 'microsoft-planner-masterclass.html', 0, 'RP'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1) t WHERE EXISTS (
        SELECT 1 FROM core_url_rewrite c WHERE c.store_id=@s AND c.request_path='microsoft-project-training.html' AND c.is_system=1));
