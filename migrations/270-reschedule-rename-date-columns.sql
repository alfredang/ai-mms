-- 270: Rename mmd_reschedule_lead.current_date -> course_start_date (current_date
--      is a MySQL reserved word and was being stored as CURRENT_DATE). Also
--      rename preferred_date -> next_course_start_date for clarity. Guarded.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_reschedule_lead' AND COLUMN_NAME='current_date');
SET @s := IF(@c=1, 'ALTER TABLE `mmd_reschedule_lead` CHANGE COLUMN `current_date` `course_start_date` VARCHAR(64) NOT NULL DEFAULT ''''', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_reschedule_lead' AND COLUMN_NAME='preferred_date');
SET @s := IF(@c=1, 'ALTER TABLE `mmd_reschedule_lead` CHANGE COLUMN `preferred_date` `next_course_start_date` VARCHAR(64) NOT NULL DEFAULT ''''', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
