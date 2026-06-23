-- 272: Disable JS merging at the CORRECT config path.
--
-- Migrations 266 and 271 wrote to dev/js/merge_js_files, which Magento NEVER
-- reads. The actual path Mage_Page_Block_Html_Head reads at line 208 is
-- `dev/js/merge_files` (no `_js_` infix — unlike CSS which uses
-- `dev/css/merge_css_files`). So 266 and 271 looked successful in the
-- migration ledger but Magento happily kept merging JS, churning out a
-- new bundle hash on every cache flush — all of which 404'd because the
-- entrypoint wipes media/js/* on every container start.
--
-- Fix mirrors 271 exactly but on the real path: nuke every override at
-- every scope, then assert the default to '0'. Pair with a cache flush
-- after the migration applies so the cached HTML stops referencing
-- whatever dead bundle URL was in flight.
DELETE FROM core_config_data WHERE path = 'dev/js/merge_files';
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'dev/js/merge_files', '0');

-- Also kill the wrong-path rows 266/271 created so the table doesn't keep
-- a dead config entry that future ops will have to puzzle over.
DELETE FROM core_config_data WHERE path = 'dev/js/merge_js_files';
