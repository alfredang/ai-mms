-- Per-session e-attendance: one row per (run, learner, session).
--
-- A class day has an AM and a PM session; a 2-day class has 4 sessions
-- (d1am, d1pm, d2am, d2pm). session_key = 'd<day><am|pm>'. Existing
-- single-row-per-learner attendance becomes the Day 1 AM session.
--
-- Guarded INFORMATION_SCHEMA + PREPARE statements (no DELIMITER — the
-- migration runner splits on ';' at end-of-line), same pattern as 011.
-- Idempotent on re-run and partner-safe: the table exists on every chain
-- via 196-course-run-attendance.sql (CREATE IF NOT EXISTS).

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'mmd_course_run_attendance'
               AND COLUMN_NAME = 'session_key');
SET @sql := IF(@has = 0,
    "ALTER TABLE `mmd_course_run_attendance` ADD COLUMN `session_key` VARCHAR(8) NOT NULL DEFAULT 'd1am' AFTER `learner_email`",
    'DO 0');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Pre-session rows (empty key can only exist if a diverged schema added the
-- column without the default) land on Day 1 AM.
UPDATE `mmd_course_run_attendance` SET `session_key` = 'd1am' WHERE `session_key` = '';

-- Replace the (run, learner) unique key with (run, learner, session).
-- Add the new key first — no duplicates are possible because the old key
-- guarantees one row per (run, learner) and they all share one session_key.
SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'mmd_course_run_attendance'
               AND INDEX_NAME = 'uk_run_learner_session');
SET @sql := IF(@has = 0,
    'ALTER TABLE `mmd_course_run_attendance` ADD UNIQUE KEY `uk_run_learner_session` (`run_id`, `learner_email`, `session_key`)',
    'DO 0');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = 'mmd_course_run_attendance'
               AND INDEX_NAME = 'uk_run_learner');
SET @sql := IF(@has > 0,
    'ALTER TABLE `mmd_course_run_attendance` DROP INDEX `uk_run_learner`',
    'DO 0');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
