-- 1872: Course feedback -> class link + consolidated-digest send log.
--
-- The public /feedback/respond form (QR on the class detail page) saves each
-- submission as a Magento product review (817) — reviews carry the product but
-- not the class. mmd_feedback_review_run records which course_runs row a review
-- came from, so MMD_FeedbackForm_Model_Cron_Digest can email one consolidated
-- summary per class to the site's own recipients. mmd_feedback_digest_sent
-- makes that send at-most-once per class.
--
-- Partner-safe: no data, no guard needed (CREATE TABLE IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS `mmd_feedback_review_run` (
    `review_id`  BIGINT UNSIGNED NOT NULL,
    `run_id`     INT UNSIGNED    NOT NULL COMMENT 'course_runs.run_id',
    `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`review_id`),
    KEY `idx_run_id` (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mmd_feedback_digest_sent` (
    `run_id`         INT UNSIGNED NOT NULL COMMENT 'course_runs.run_id',
    `response_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `recipients`     VARCHAR(512) NOT NULL DEFAULT '',
    `sent_at`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
