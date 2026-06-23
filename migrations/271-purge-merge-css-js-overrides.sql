-- 271: Purge every scope-level override of dev/css/merge_css_files and
--      dev/js/merge_js_files, then reassert the default to '0'.
--
-- Background: migration 266 disabled CSS/JS merging at the DEFAULT scope, but
-- prod is STILL emitting merged-bundle URLs in admin HTML — confirmed by a
-- diagnostic that showed the merged bundle hash regenerating on each cache
-- flush. Root cause: Magento's config inheritance is default → website →
-- store, so a leftover website- or store-scoped row in core_config_data with
-- value '1' shadows the default '0'. The "View As" feature in the admin
-- header makes admin pages load whichever store context the operator is
-- viewing under, so a single website override is enough to keep the broken
-- merged bundle URL baked into the HTML.
--
-- Fix: delete EVERY existing row at any scope, then INSERT the default '0'.
-- After this runs there is exactly one row per path, scope=default, value=0,
-- and no scope can override it because no overrides exist.
DELETE FROM core_config_data WHERE path IN ('dev/css/merge_css_files', 'dev/js/merge_js_files');
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
    ('default', 0, 'dev/css/merge_css_files', '0'),
    ('default', 0, 'dev/js/merge_js_files',  '0');
