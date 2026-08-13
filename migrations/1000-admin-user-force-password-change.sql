-- Force-password-change flag for admin_user.
--
-- Set to 1 when an account's password was assigned FOR the user (bulk default
-- password, admin reset) rather than chosen by them. Both login paths
-- (/lmslogin + /adminlogin) redirect such a session to the change-password
-- screen and refuse to let it go anywhere else until a new password is saved,
-- at which point the flag is cleared.
--
-- Idempotent: the ADD COLUMN is guarded so re-running (or running against a
-- partner DB that already has it) is a no-op rather than error 1060.

SET @col_exists := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME   = 'admin_user'
       AND COLUMN_NAME  = 'mmd_force_password_change'
);

SET @ddl := IF(@col_exists = 0,
    'ALTER TABLE `admin_user`
        ADD COLUMN `mmd_force_password_change` TINYINT(1) NOT NULL DEFAULT 0
        COMMENT ''1 = password was assigned, user must set their own at next login''',
    'DO 0'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
