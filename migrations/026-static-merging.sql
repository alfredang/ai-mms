-- Enable Magento's built-in JS/CSS file merging.
-- Collapses dozens of tiny <script>/<link> requests into a few merged bundles
-- under media/js/ and media/css/, dropping page load time substantially.
-- Magento auto-rebuilds the merged bundles when source files change, so no
-- maintenance burden — but `var/cache` should be cleared on deploy (already
-- handled by docker/entrypoint.sh).
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
    ('default', 0, 'dev/js/merge_files',      '1'),
    ('default', 0, 'dev/css/merge_files_css', '1')
ON DUPLICATE KEY UPDATE value = VALUES(value);
