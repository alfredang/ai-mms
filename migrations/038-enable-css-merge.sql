-- Enable CSS file merging admin-wide (System → Configuration → Developer →
-- CSS Settings → Merge CSS Files). Magento concatenates all CSS that the
-- layout marks as mergeable into a single hashed file under media/css/, so
-- every admin page goes from ~12 stylesheet HTTP requests down to 1.
--
-- Idempotent: ON DUPLICATE KEY UPDATE makes this safe to re-run, and the
-- WHERE-style fallback covers the case where the row already exists at a
-- different scope.
--
-- Note: dev/js/merge_files is already 1 in this DB; only the CSS counterpart
-- was left off (likely from an earlier debugging session that never got
-- flipped back). No JS-side change is needed.

INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'dev/css/merge_css_files', '1')
ON DUPLICATE KEY UPDATE value = '1';

-- The above INSERT only matches if (scope,scope_id,path) has a UNIQUE index.
-- Magento 1's core_config_data has UNIQUE KEY CONFIG_SCOPE_SCOPE_ID_PATH so
-- the upsert is exact. Belt-and-braces: also flip any pre-existing row that
-- might have been seeded under a different scope.
UPDATE core_config_data SET value = '1' WHERE path = 'dev/css/merge_css_files';
