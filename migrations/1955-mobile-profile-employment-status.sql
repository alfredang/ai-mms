-- Native apps (TC LMS SG / MY / GH): employment status on the learner profile,
-- the same three choices as the TIA TMS app (Employed / Unemployed / Looking for
-- Job). Stored in mmd_mobile_profile beside the appearance and phone number.
-- Runs identically on every site; idempotent.

SET @c = (SELECT COUNT(*) FROM information_schema.COLUMNS
          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_mobile_profile' AND COLUMN_NAME = 'employment_status');
SET @sql = IF(@c = 0,
    'ALTER TABLE `mmd_mobile_profile` ADD COLUMN `employment_status` VARCHAR(20) NULL AFTER `phone`',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
