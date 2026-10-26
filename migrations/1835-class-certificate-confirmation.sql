-- 1835: Final attendance confirmation before certificates (MY partner rule, 22 Oct 2026).
--
-- "Once the trainer confirms final attendance, automatically send certificates to participants with at least 75%
-- of training hours." On the Malaysia site each class gets rows here; the LATEST row is the class's current state:
--   confirmed — the trainer confirmed the final attendance (below_list = the learners under 75% at that time);
--               certificates are sent to the other learners
--   reopened  — attendance changed after the confirmation; it must be recorded again before anything is issued
--   excluded  — the class is excluded from certificate generation and sending (e.g. handled separately)
--
-- Schema only: no data is written, so it is safe on every site (SG/MY/GH). Idempotent (CREATE IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS `mmd_course_run_cert_confirmation` (
    `confirmation_id`      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `run_id`               INT UNSIGNED  NOT NULL,
    `class_id`             VARCHAR(20)   NULL,
    `status`               VARCHAR(16)   NOT NULL COMMENT 'confirmed | reopened | excluded',
    `trainer_name`         VARCHAR(255)  NULL,
    `below_list`           TEXT          NULL     COMMENT 'JSON [{email,name,pct}] of learners under 75% when confirmed',
    `note`                 VARCHAR(500)  NULL,
    `recorded_by_admin_id` INT UNSIGNED  NULL,
    `recorded_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`confirmation_id`),
    KEY `idx_run` (`run_id`, `confirmation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
