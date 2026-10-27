-- The C769 pilot verified real trainer and learner OTP login plus access to
-- the imported class, virtual link, and all learner courseware on 2026-10-27.
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'mmd/tms_handover/access_verified', '1')
ON DUPLICATE KEY UPDATE value = VALUES(value);
