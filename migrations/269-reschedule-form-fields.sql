-- 269: Class Reschedule form redesign — add NRIC + course_code columns.
--      Existing columns reused: course=Course Title, current_date=Course Start
--      Date, preferred_date=Next Course Start Date. Guarded so re-runs are no-ops.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_reschedule_lead' AND COLUMN_NAME='nric');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_reschedule_lead` ADD COLUMN `nric` VARCHAR(32) NOT NULL DEFAULT '''' AFTER `name`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_reschedule_lead' AND COLUMN_NAME='course_code');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_reschedule_lead` ADD COLUMN `course_code` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `course`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
