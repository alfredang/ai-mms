-- Disable admin access for Evan Ang and Alisha Go.
-- Keyed on email so it is safe on every partner server (user_id differs per DB).
-- Idempotent: re-running is a no-op.
UPDATE admin_user
   SET is_active = 0
 WHERE email IN ('evan@tertiaryinfotech.com', 'alisha.go.sihua@gmail.com');
