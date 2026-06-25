-- 274: Add gcal_status and gcal_error columns to mmd_reschedule_lead
--      for tracking Google Calendar attendee-sync results. Guarded.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_reschedule_lead' AND COLUMN_NAME='gcal_status');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_reschedule_lead` ADD COLUMN `gcal_status` VARCHAR(16) NOT NULL DEFAULT ''pending'' AFTER `status`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mmd_reschedule_lead' AND COLUMN_NAME='gcal_error');
SET @s := IF(@c=0, 'ALTER TABLE `mmd_reschedule_lead` ADD COLUMN `gcal_error` TEXT NULL AFTER `gcal_status`', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
