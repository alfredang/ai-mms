-- Class Announcements: a trainer posts a message and/or one document to a
-- class; every learner enrolled in that class reads it on their class page.
-- One row per post, keyed to course_runs.run_id. Runs on every site (SG/MY/GH),
-- schema only, no data. Safe to re-run.

CREATE TABLE IF NOT EXISTS `mmd_class_announcement` (
    `announcement_id`   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_id`            INT UNSIGNED NOT NULL,
    `message`           TEXT NULL,
    `file_name`         VARCHAR(255) NULL,
    `file_url`          VARCHAR(1000) NULL,
    `file_key`          VARCHAR(500) NULL COMMENT 'R2 object key, used to delete the document with the post',
    `posted_by`         VARCHAR(255) NOT NULL,
    `posted_by_user_id` INT UNSIGNED NULL,
    `created_at`        DATETIME NOT NULL COMMENT 'UTC',
    PRIMARY KEY (`announcement_id`),
    KEY `idx_mmd_class_announcement_run` (`run_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
