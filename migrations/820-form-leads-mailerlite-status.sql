-- Track MailerLite subscription outcome on every website-form lead table
-- (franchise / corporate / customised / hiring), mirroring migration 819
-- for mmd_lead. Values: NULL = never attempted, 'sent', 'skipped', 'failed'.
--
-- Idempotent (information_schema guard + prepared statement) and table-guarded,
-- so it is a no-op on any partner DB where a table is absent or already migrated.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_lead' AND COLUMN_NAME = 'mailerlite_status');
SET @t := (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_lead');
SET @s := IF(@t > 0 AND @c = 0, 'ALTER TABLE mmd_franchise_lead ADD COLUMN mailerlite_status VARCHAR(20) NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_corporate_lead' AND COLUMN_NAME = 'mailerlite_status');
SET @t := (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_corporate_lead');
SET @s := IF(@t > 0 AND @c = 0, 'ALTER TABLE mmd_corporate_lead ADD COLUMN mailerlite_status VARCHAR(20) NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_customised_lead' AND COLUMN_NAME = 'mailerlite_status');
SET @t := (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_customised_lead');
SET @s := IF(@t > 0 AND @c = 0, 'ALTER TABLE mmd_customised_lead ADD COLUMN mailerlite_status VARCHAR(20) NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_hiring_lead' AND COLUMN_NAME = 'mailerlite_status');
SET @t := (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_hiring_lead');
SET @s := IF(@t > 0 AND @c = 0, 'ALTER TABLE mmd_hiring_lead ADD COLUMN mailerlite_status VARCHAR(20) NULL DEFAULT NULL', 'DO 0');
PREPARE st FROM @s;
EXECUTE st;
DEALLOCATE PREPARE st;
