-- Grant Danny Choy (danny@tertiaryinfotech.com) all six MMD roles. SG ONLY.
--
-- SG-only: Danny is Singapore staff, so this must not create an admin account
-- on the MY / GH partner-operated servers, which run this same migration
-- chain. The instance comes from apply.php's @mms_instance (the container's
-- MMS_COUNTRY_CODE env, unset => 'SG') - never from a data fingerprint.
-- Every statement below is DML, so the guard is an inline WHERE @is_sg = 1
-- rather than a PREPARE wrapper (a PREPARE of a no-op SELECT would silently
-- skip the real work while apply.php still printed OK).
--
-- Idempotent and safe to re-run:
--   * Creates the admin_user only if the email is absent. Login is email-based
--     (MMD_EmailLogin), so username mirrors email. is_active = 1.
--   * No usable password is set: the hash below matches nothing, and Danny
--     sets his own via "Forgot password". A real credential must never enter
--     git history - this repo has a prior key-leak incident.
--   * Grants all six role codes via INSERT IGNORE on the UNQ_USER_ROLE
--     (user_id, role_code) unique key, with training_provider (Super Admin)
--     as the primary role.
--   * The admin_role (ACL) row is intentionally NOT written here -
--     MMD_RoleManager_Helper_Data::applyRoleAcl() creates/updates it at login
--     from the selected role, resolving the ACL group by name.

SET @is_sg := IF(@mms_instance = 'SG', 1, 0);
SET @danny_email := 'danny@tertiaryinfotech.com';
SET @danny_id := (SELECT user_id FROM admin_user WHERE email = @danny_email LIMIT 1);

INSERT INTO admin_user (username, firstname, lastname, email, password, created, modified, is_active)
SELECT @danny_email, 'Danny', 'Choy', @danny_email,
       -- Placeholder: not a usable password. Reset via "Forgot password".
       CONCAT(SHA2(CONCAT('mmd-placeholder-', @danny_email, UUID()), 256), ':xx'),
       NOW(), NOW(), 1
FROM DUAL
WHERE @is_sg = 1 AND @danny_id IS NULL;

SET @danny_id := (SELECT user_id FROM admin_user WHERE email = @danny_email LIMIT 1);

-- Make sure an existing account is active and named correctly.
UPDATE admin_user
   SET firstname = 'Danny', lastname = 'Choy', is_active = 1
 WHERE @is_sg = 1 AND user_id = @danny_id;

-- Grant all six roles. is_primary flags training_provider (Super Admin).
INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT @danny_id, r.code, r.is_primary, NOW()
FROM (
    SELECT 'learner'           AS code, 0 AS is_primary
    UNION ALL SELECT 'trainer',           0
    UNION ALL SELECT 'developer',         0
    UNION ALL SELECT 'marketing',         0
    UNION ALL SELECT 'admin',             0
    UNION ALL SELECT 'training_provider', 1
) r
WHERE @is_sg = 1 AND @danny_id IS NOT NULL;

-- Re-runs: ensure exactly one primary, on training_provider.
UPDATE mmd_user_role_map
   SET is_primary = IF(role_code = 'training_provider', 1, 0)
 WHERE @is_sg = 1 AND user_id = @danny_id;
