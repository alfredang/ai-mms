-- Per-class virtual training link + Google Calendar event id on course_runs.
--
-- virtual_link: the Zoom / Google Meet / Teams link for ONE class. The trainer
-- and learner class pages ("Virtual Training Link" card) read it first and fall
-- back to the older per-course course_courseware.google_meet_url.
-- gcal_event_id: the site calendar event this class is linked to, set by the
-- Google Calendar sync cron (MMD_RoleManager_Model_Cron_GoogleCalendarSync)
-- when it finds or creates the event; NULL = not yet synced.
--
-- Schema only, no content — safe on every site. Self-healing via
-- INFORMATION_SCHEMA + PREPARE (same pattern as 050).

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'course_runs'
               AND COLUMN_NAME = 'virtual_link');
SET @sql := IF(@has = 0,
    'ALTER TABLE course_runs ADD COLUMN `virtual_link` VARCHAR(512) NULL DEFAULT NULL AFTER `mode_of_training`',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'course_runs'
               AND COLUMN_NAME = 'gcal_event_id');
SET @sql := IF(@has = 0,
    'ALTER TABLE course_runs ADD COLUMN `gcal_event_id` VARCHAR(255) NULL DEFAULT NULL AFTER `virtual_link`',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
