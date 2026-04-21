-- Stop admins getting logged out "due to inactivity" on the live site.
--
-- Root cause: OpenMage's Mage_Core_Model_Session_Abstract_Varien validates
-- each request against a fingerprint of REMOTE_ADDR + HTTP_VIA +
-- HTTP_X_FORWARDED_FOR + HTTP_USER_AGENT captured at session start. Behind
-- Coolify's reverse proxy (and any CDN in front of it) the X-Forwarded-For
-- chain legitimately varies per request — the session then fails
-- validation and is destroyed, which the user experiences as an
-- "inactivity" logout after being away for a while (their return request
-- has a different XFF chain).
--
-- Fix: disable the four header-based validators. REMOTE_ADDR behind a
-- proxy is the proxy's IP which is stable, so losing that check is fine;
-- losing the others matches the guidance in OpenMage's docs for
-- reverse-proxy deployments.
--
-- Keeps in place: cookie lifetime (migration 015) and password-timestamp
-- check (still honoured, still invalidates on real password rotation).
INSERT INTO core_config_data (scope, scope_id, path, value) VALUES
    ('default', 0, 'web/session/use_remote_addr',          '0'),
    ('default', 0, 'web/session/use_http_via',             '0'),
    ('default', 0, 'web/session/use_http_x_forwarded_for', '0'),
    ('default', 0, 'web/session/use_http_user_agent',      '0')
ON DUPLICATE KEY UPDATE value = VALUES(value);
