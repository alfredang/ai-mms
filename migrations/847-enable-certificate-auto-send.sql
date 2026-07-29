-- Enable the Certificate of Achievement auto-send sweep (owner request
-- 2026-07-29): certificates are emailed automatically to learners at 6:30pm
-- daily (MMD_Certificate cron mmd_certificate_auto_send) once their class is
-- completed and their OVERALL session attendance exceeds 70%
-- (MMD_Certificate_Helper_Data::getEligibleLearners).
--
-- The cron ships fail-safe OFF (absent config = disabled); this seeds the
-- flag ON. The admin toggle on the E-Attendance page can still turn it off
-- afterwards (this migration runs once per DB and never re-applies).
-- Partner-safe: core_config_data exists on every chain; idempotent via the
-- unique (scope, scope_id, path) key.

INSERT INTO `core_config_data` (`scope`, `scope_id`, `path`, `value`)
VALUES ('default', 0, 'mmd/certificate/auto_enabled', '1')
ON DUPLICATE KEY UPDATE `value` = '1';
