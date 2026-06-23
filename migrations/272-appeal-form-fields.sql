-- 272: Assessment Appeal form redesign — add NRIC, course_code, course_start_date,
--      course_end_date. Existing reused: course=Course Title, assessment_date,
--      message=Reason to Appeal. Guarded so re-runs are no-ops.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_appeal_lead' AND COLUMN_NAME='nric');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_appeal_lead` ADD COLUMN `nric` VARCHAR(32) NOT NULL DEFAULT '''' AFTER `name`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_appeal_lead' AND COLUMN_NAME='course_code');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_appeal_lead` ADD COLUMN `course_code` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `course`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_appeal_lead' AND COLUMN_NAME='course_start_date');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_appeal_lead` ADD COLUMN `course_start_date` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `course_code`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_appeal_lead' AND COLUMN_NAME='course_end_date');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_appeal_lead` ADD COLUMN `course_end_date` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `course_start_date`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
