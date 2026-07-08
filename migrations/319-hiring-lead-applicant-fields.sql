-- 319: Hiring form redesign — add applicant profile fields to mmd_hiring_lead.
--      roles (role applying for), nationality, race, gender, highest_qualification,
--      marital_status, age_range. Existing `position` column is retained (the Role
--      dropdown writes to `roles`). Additive + guarded so re-runs are no-ops and it is
--      safe on every partner DB (the table ships with the MMD_Hiring module on all sites).
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_hiring_lead' AND COLUMN_NAME='roles');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_hiring_lead` ADD COLUMN `roles` VARCHAR(255) NOT NULL DEFAULT '''' AFTER `position`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_hiring_lead' AND COLUMN_NAME='nationality');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_hiring_lead` ADD COLUMN `nationality` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `roles`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_hiring_lead' AND COLUMN_NAME='race');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_hiring_lead` ADD COLUMN `race` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `nationality`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_hiring_lead' AND COLUMN_NAME='gender');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_hiring_lead` ADD COLUMN `gender` VARCHAR(32) NOT NULL DEFAULT '''' AFTER `race`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_hiring_lead' AND COLUMN_NAME='highest_qualification');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_hiring_lead` ADD COLUMN `highest_qualification` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `gender`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_hiring_lead' AND COLUMN_NAME='marital_status');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_hiring_lead` ADD COLUMN `marital_status` VARCHAR(32) NOT NULL DEFAULT '''' AFTER `highest_qualification`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_hiring_lead' AND COLUMN_NAME='age_range');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_hiring_lead` ADD COLUMN `age_range` VARCHAR(32) NOT NULL DEFAULT '''' AFTER `marital_status`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
