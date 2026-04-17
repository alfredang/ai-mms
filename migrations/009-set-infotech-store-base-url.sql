-- Set base URLs for Infotech store view (store_id = 7)
-- Maps www.tertiaryinfotech.edu.sg to the Infotech store
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
('stores', 7, 'web/unsecure/base_url', 'https://www.tertiaryinfotech.edu.sg/'),
('stores', 7, 'web/secure/base_url', 'https://www.tertiaryinfotech.edu.sg/'),
('stores', 7, 'web/secure/use_in_frontend', '1'),
('stores', 7, 'web/secure/use_in_adminhtml', '1')
ON DUPLICATE KEY UPDATE value = VALUES(value);
