-- Disable admin login captcha for local development.
-- The captcha images are auto-generated and can fail to render if the
-- captcha font/directory permissions aren't right in the dev container.

UPDATE core_config_data SET value='0' WHERE path='admin/captcha/enable';
