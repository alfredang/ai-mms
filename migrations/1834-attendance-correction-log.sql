-- 1834: Attendance correction log (MY partner rule, 22 Oct 2026).
--
-- "Admins may correct genuine attendance-record errors with a recorded reason, but must not bypass the
-- threshold." On the Malaysia site, any change to a learner's attendance (present/absent or actual minutes)
-- for a class that has already finished must carry a reason; each change is written here with the old and
-- new values, the reason, who made it and when. The 75% certificate rule itself is unchanged.
--
-- Schema only: no data is written, so it is safe on every site (SG/MY/GH). Idempotent (CREATE IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS `mmd_course_run_attendance_log` (
    `log_id`              INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `run_id`              INT UNSIGNED      NOT NULL,
    `class_id`            VARCHAR(20)       NULL,
    `learner_email`       VARCHAR(255)      NOT NULL,
    `session_key`         VARCHAR(8)        NOT NULL,
    `old_present`         TINYINT(1)        NULL     COMMENT 'NULL = no record before',
    `new_present`         TINYINT(1)        NOT NULL,
    `old_minutes`         SMALLINT UNSIGNED NULL,
    `new_minutes`         SMALLINT UNSIGNED NULL,
    `reason`              VARCHAR(500)      NOT NULL,
    `changed_by_admin_id` INT UNSIGNED      NULL,
    `changed_at`          DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`log_id`),
    KEY `idx_run` (`run_id`),
    KEY `idx_run_learner` (`run_id`, `learner_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
