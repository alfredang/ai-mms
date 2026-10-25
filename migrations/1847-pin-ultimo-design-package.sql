-- Pin the storefront design package to Ultimo.
--
-- 2026-10-25: SG prod rendered with Magento's stock default/default theme (broken logo,
-- logo_alt as a giant link, no banners) because core_config_data design/package/name had
-- been switched from 'ultimo' to 'default' by a runtime config save (not a deploy). It was
-- hot-fixed on prod; this re-asserts it on every DB the migration chain builds.
--
-- Every site (SG/MY/GH) runs Ultimo, so no instance guard. design/theme/* stay NULL
-- (= 'default' theme -> skin/frontend/ultimo/default). Idempotent.

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'design/package/name', 'ultimo')
ON DUPLICATE KEY UPDATE value = 'ultimo';

-- a website/store-scoped override would shadow the default-scope value
DELETE FROM core_config_data
 WHERE path = 'design/package/name'
   AND scope IN ('websites', 'stores')
   AND (value IS NULL OR value <> 'ultimo');
