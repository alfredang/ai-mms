-- Effectively disable the admin auto-logout. Supersedes migration 022's
-- 20-min idle window. Both server-side (admin/security/session_lifetime)
-- and cookie-side (admin/security/session_cookie_lifetime) get pushed to
-- one year (31,536,000 seconds) so users stop getting kicked out.
--
-- Paired with session.gc_maxlifetime = 31536000 in docker/php.ini so PHP
-- doesn't garbage-collect the session file before Magento's window
-- expires.
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
    ('default', 0, 'admin/security/session_cookie_lifetime', '31536000'),
    ('default', 0, 'admin/security/session_lifetime',        '31536000')
ON DUPLICATE KEY UPDATE value = VALUES(value);
