-- 266: Disable CSS/JS merge globally. The merged admin bundle (media/css_secure)
--      fails to generate on prod (HTTP 500), leaving the admin completely
--      unstyled while localhost (where the bundle happens to build) looks fine.
--      Individual skin CSS/JS files all exist and serve 200, so loading them
--      directly is reliable and identical across environments. Flush cache after.
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'dev/css/merge_css_files', '0')
  ON DUPLICATE KEY UPDATE value = '0';
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES ('default', 0, 'dev/js/merge_js_files', '0')
  ON DUPLICATE KEY UPDATE value = '0';
