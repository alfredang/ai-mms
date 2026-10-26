-- 1833: Per-class session timetable + actual minutes attended (MY attendance-by-hours).
--
-- MY partner rule (21 Oct 2026): certificate eligibility = training minutes
-- attended / total scheduled training minutes >= 75%, no rounding up. Each
-- session's duration comes from the class's confirmed timetable (scheduled
-- start/end minus the actual non-training breaks) and is SAVED with the class.
-- Missing times/breaks are flagged for admin confirmation, never assumed.
--
--   mmd_course_run_session  one row per class session (run_id + session_key:
--                           'd1am' / 'd1pm' for day classes, 'd1ev' for an
--                           evening). Rows are written only when an admin
--                           confirms the timetable; until then the code
--                           proposes sessions from course_runs start/end
--                           times and the class stays flagged.
--   mmd_course_run_attendance.minutes_attended
--                           NULL = the tick counts the whole session; a
--                           number = actual minutes for a late arrival or
--                           early departure.
--
-- Schema only: no data is written, so it is safe on every site (SG/MY/GH).
-- Idempotent: CREATE IF NOT EXISTS + guarded ALTER (no-op branch is 'DO 0',
-- never 'SELECT 1' — feedback_migration_prepare_select1_noop_breaks_applyphp).

CREATE TABLE IF NOT EXISTS `mmd_course_run_session` (
    `session_id`            INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `run_id`                INT UNSIGNED      NOT NULL,
    `session_key`           VARCHAR(8)        NOT NULL COMMENT 'd<day>am / d<day>pm / d<day>ev',
    `session_date`          DATE              NULL,
    `start_time`            TIME              NULL,
    `end_time`              TIME              NULL,
    `break_minutes`         SMALLINT UNSIGNED NULL     COMMENT 'non-training breaks inside start..end; NULL = not entered',
    `training_minutes`      SMALLINT UNSIGNED NULL     COMMENT 'end - start - break_minutes, saved on confirm',
    `is_confirmed`          TINYINT(1)        NOT NULL DEFAULT 0,
    `confirmed_by_admin_id` INT UNSIGNED      NULL,
    `confirmed_at`          DATETIME          NULL,
    `note`                  VARCHAR(255)      NULL,
    `created_at`            DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`session_id`),
    UNIQUE KEY `uk_run_session` (`run_id`, `session_key`),
    KEY `idx_run` (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'mmd_course_run_attendance'
               AND COLUMN_NAME = 'minutes_attended');
SET @sql := IF(@has = 0,
    'ALTER TABLE `mmd_course_run_attendance` ADD COLUMN `minutes_attended` SMALLINT UNSIGNED NULL DEFAULT NULL AFTER `is_present`',
    'DO 0');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
