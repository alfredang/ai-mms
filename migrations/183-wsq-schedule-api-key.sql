-- Seed a random API key for the WSQ Schedule public API at default scope.
-- (A fixed literal used to live here; it was public in git — never put key values in migrations.)
-- Replace via System → Configuration → MMD → Provider Manager → WSQ Schedule API Key
-- after first deploy. Idempotent: INSERT IGNORE skips on re-run.
INSERT IGNORE INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'courses/general/wsq_schedule_api_key', SHA2(CONCAT(UUID(), RAND()), 256));
