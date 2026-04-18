-- Effectively disable admin session timeout by setting cookie lifetime
-- to ~100 years (3155692600 seconds, the OpenMage maximum).
-- Paired with session.gc_maxlifetime=3155692600 in docker/php.ini so the
-- server-side session data survives as well.
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'admin/security/session_cookie_lifetime', '3155692600')
ON DUPLICATE KEY UPDATE value = '3155692600';
