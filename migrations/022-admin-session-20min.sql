-- Admin sessions: 20 minutes of inactivity before logout.
-- Supersedes migration 015 (which was 100 years). Paired with
-- session.gc_maxlifetime=1200 in docker/php.ini so server-side
-- session data is GC'd at the same cadence.
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
    ('default', 0, 'admin/security/session_cookie_lifetime', '1200'),
    ('default', 0, 'admin/security/session_lifetime',        '1200')
ON DUPLICATE KEY UPDATE value = VALUES(value);
