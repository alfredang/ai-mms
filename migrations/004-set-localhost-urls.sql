-- Point Magento at http://localhost:8080 and disable HTTPS in frontend/admin
-- for local development. Required after importing the production DB dump.

UPDATE core_config_data SET value='http://localhost:8080/' WHERE path IN ('web/unsecure/base_url','web/secure/base_url');
UPDATE core_config_data SET value='0' WHERE path='web/secure/use_in_frontend';
UPDATE core_config_data SET value='0' WHERE path='web/secure/use_in_adminhtml';
