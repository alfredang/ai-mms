-- 301 redirect from the OLD slug of the course renamed in 602.
--
--   elearning-instructional-design.html -> generative-ai-for-curriculum-development.html
--
-- MUST run AFTER the catalog_url reindex that 602 requires — the reindex
-- regenerates core_url_rewrite and would otherwise clobber / re-point this
-- row. (memory: catalog_url reindex regenerates disabled-category 301 -> 404)
--
-- Deliberately NOT using INSERT IGNORE: a category/product may already own the
-- request_path via an is_system=1 row, in which case IGNORE silently no-ops and
-- the 301 never ships. We DELETE any non-system squatter on the old path first,
-- then insert, then the deploy notes assert the old URL returns 301.
-- (memory: INSERT IGNORE into core_url_rewrite silently no-ops)
--
-- Store 1 (SG) only — this is an SG C-prefix course. Idempotent.

SET @s := 1;

DELETE FROM core_url_rewrite
WHERE store_id = @s AND is_system = 0
  AND request_path = 'elearning-instructional-design.html';

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT @s, 'rp_c505_old', 'elearning-instructional-design.html', 'generative-ai-for-curriculum-development.html', 0, 'RP'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1) t WHERE EXISTS (
        SELECT 1 FROM core_url_rewrite c WHERE c.store_id=@s AND c.request_path='elearning-instructional-design.html' AND c.is_system=1));
