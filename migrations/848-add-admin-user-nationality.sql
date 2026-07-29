-- Add admin_user.nationality for the My Profile page (Edit Profile
-- previously showed Race / Gender / NRIC but had no Nationality field).
-- Free-text VARCHAR — partner-neutral (SG/MY/GH all deploy this schema).
-- Guarded by an information_schema existence check + prepared statement,
-- same pattern as 111-readd-admin-user-profile-fields.sql, so it is
-- fully idempotent and a no-op where the column already exists.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'admin_user' AND COLUMN_NAME = 'nationality');
SET @s := IF(@c = 0, 'ALTER TABLE admin_user ADD COLUMN nationality VARCHAR(64) DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;
