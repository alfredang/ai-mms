-- 1940 — class Certificate page: per-learner checklist kept by the trainer.
--
-- feedback_done = the trainer ticked "learner has completed the course feedback".
-- One row per (class, learner email). Not a registration table: the roster stays
-- course_run_enrolments / the order history.
--
-- Partner-safe: no data, no guard needed (CREATE TABLE IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS `mmd_course_run_cert_checklist` (
    `checklist_id`        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_id`              INT UNSIGNED NOT NULL,
    `learner_email`       VARCHAR(255) NOT NULL,
    `feedback_done`       TINYINT(1) NOT NULL DEFAULT 0,
    `updated_by_admin_id` INT UNSIGNED NULL,
    `updated_at`          DATETIME NULL,
    PRIMARY KEY (`checklist_id`),
    UNIQUE KEY `uq_run_learner` (`run_id`, `learner_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
