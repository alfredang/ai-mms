-- Point Magento at http://localhost:8080 and disable HTTPS in frontend/admin
-- for local development. Required after importing the production DB dump.
--
-- Important: a fresh prod dump carries per-STORE base_url overrides
-- (scope='stores') pointing at the live country domains
-- (tertiarycourses.com.sg, .com.my, .com.gh, .com.ng, tertiaryinfotech.edu.sg).
-- Updating only the default scope leaves those store rows intact, so
-- MAGE_RUN_CODE dispatch happily sends localhost traffic to the live
-- domain. Wipe ALL scopes — store rows fall back to the default.

DELETE FROM core_config_data
 WHERE scope='stores'
   AND path IN ('web/unsecure/base_url','web/secure/base_url',
                'web/secure/use_in_frontend','web/secure/use_in_adminhtml',
                'web/url/redirect_to_base');

DELETE FROM core_config_data
 WHERE scope='websites'
   AND path IN ('web/unsecure/base_url','web/secure/base_url',
                'web/secure/use_in_frontend','web/secure/use_in_adminhtml',
                'web/url/redirect_to_base');

UPDATE core_config_data SET value='http://localhost:8080/'
 WHERE scope='default' AND path IN ('web/unsecure/base_url','web/secure/base_url');
UPDATE core_config_data SET value='0' WHERE scope='default' AND path='web/secure/use_in_frontend';
UPDATE core_config_data SET value='0' WHERE scope='default' AND path='web/secure/use_in_adminhtml';
UPDATE core_config_data SET value='0' WHERE scope='default' AND path='web/url/redirect_to_base';

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'web/url/redirect_to_base', '0'
 WHERE NOT EXISTS (SELECT 1 FROM core_config_data WHERE scope='default' AND path='web/url/redirect_to_base');
