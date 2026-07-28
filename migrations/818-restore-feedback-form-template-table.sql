-- 818: Restore the feedback form TEMPLATE table (dropped by 817).
-- The Form Builder returns as part of Reviews & Ratings (Marketing role):
-- the public /feedback/respond form stays template-driven, while submissions
-- keep saving into the Magento review system (review + rating_option_vote).
-- The response table stays gone — reviews are the single response store.
-- Idempotent + partner-safe (CREATE TABLE IF NOT EXISTS; auto-seeded on
-- first use by MMD_FeedbackForm_Helper_Data::getOrCreateTemplate()).

CREATE TABLE IF NOT EXISTS `mmd_feedback_form_template` (
    `template_id`  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `title`        VARCHAR(255)  NOT NULL DEFAULT 'Course Feedback Form',
    `sections`     LONGTEXT      NOT NULL COMMENT 'JSON array of section objects',
    `is_active`    TINYINT(1)    NOT NULL DEFAULT 1,
    `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
