-- Finger signatures taken in the TC LMS apps (iOS + Android) for e-attendance.
--
-- One row per (class run, session, signer, role). A learner signs to check in
-- (on their own phone, or on the trainer's phone); the trainer signs for each
-- session they teach. The attendance itself stays in mmd_course_run_attendance;
-- this table only holds the signature image (PNG, black ink on transparent).
-- Partner-safe: CREATE IF NOT EXISTS, same on SG / MY / GH.

CREATE TABLE IF NOT EXISTS `mmd_attendance_signature` (
    `signature_id`       INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `run_id`             INT UNSIGNED  NOT NULL,
    `class_id`           VARCHAR(20)   NULL,
    `session_key`        VARCHAR(16)   NOT NULL,
    `signer_email`       VARCHAR(255)  NOT NULL,
    `signer_name`        VARCHAR(255)  NULL,
    `signer_role`        VARCHAR(10)   NOT NULL COMMENT 'learner | trainer',
    `image_png`          MEDIUMBLOB    NOT NULL,
    `captured_by_email`  VARCHAR(255)  NULL     COMMENT 'account signed in on the device that took it',
    `signed_at`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`signature_id`),
    UNIQUE KEY `uk_run_session_signer` (`run_id`, `session_key`, `signer_email`, `signer_role`),
    KEY `idx_run` (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
