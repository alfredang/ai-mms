-- 301 redirects from the OLD slugs of the three courses renamed in 595.
--
--   performance-management.html      -> ai-for-performance-management.html
--   career-coaching-fundamentals.html-> ai-for-career-coaching.html
--   coaching-and-mentoring.html      -> ai-for-talent-management.html
--
-- MUST run AFTER the catalog_url reindex that 595 requires — the reindex
-- regenerates core_url_rewrite and would otherwise clobber / re-point these
-- rows. (memory: catalog_url reindex regenerates disabled-category 301 -> 404)
--
-- Deliberately NOT using INSERT IGNORE: a category/product may already own the
-- request_path via an is_system=1 row, in which case IGNORE silently no-ops and
-- the 301 never ships. We DELETE any non-system squatter on the old path first,
-- then insert, then the deploy notes assert each old URL returns 301.
-- (memory: INSERT IGNORE into core_url_rewrite silently no-ops)
--
-- Store 1 (SG) only — these are SG C-prefix courses. Idempotent.

SET @s := 1;

-- Old root-level slugs -> new root-level slugs.
DELETE FROM core_url_rewrite
WHERE store_id = @s AND is_system = 0
  AND request_path IN (
    'performance-management.html',
    'career-coaching-fundamentals.html',
    'coaching-and-mentoring.html');

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT @s, 'rp_c1065_old', 'performance-management.html', 'ai-for-performance-management.html', 0, 'RP'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1) t WHERE EXISTS (
        SELECT 1 FROM core_url_rewrite c WHERE c.store_id=@s AND c.request_path='performance-management.html' AND c.is_system=1));

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT @s, 'rp_c431_old', 'career-coaching-fundamentals.html', 'ai-for-career-coaching.html', 0, 'RP'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1) t WHERE EXISTS (
        SELECT 1 FROM core_url_rewrite c WHERE c.store_id=@s AND c.request_path='career-coaching-fundamentals.html' AND c.is_system=1));

INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT @s, 'rp_c1178_old', 'coaching-and-mentoring.html', 'ai-for-talent-management.html', 0, 'RP'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM (SELECT 1) t WHERE EXISTS (
        SELECT 1 FROM core_url_rewrite c WHERE c.store_id=@s AND c.request_path='coaching-and-mentoring.html' AND c.is_system=1));
