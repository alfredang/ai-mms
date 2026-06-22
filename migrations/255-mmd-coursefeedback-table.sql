-- 255: Course Feedback store for MMD_CourseFeedback. Mirrors the LMS class
--      feedback form fields (course details + three 1-5 ratings + comments).
CREATE TABLE IF NOT EXISTS `mmd_coursefeedback_lead` (
  `lead_id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `store_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `store_code` VARCHAR(32) NOT NULL DEFAULT '', `name` VARCHAR(255) NOT NULL DEFAULT '',
  `email` VARCHAR(255) NOT NULL DEFAULT '', `telephone` VARCHAR(64) NOT NULL DEFAULT '',
  `course` VARCHAR(255) NOT NULL DEFAULT '', `course_code` VARCHAR(64) NOT NULL DEFAULT '',
  `trainer` VARCHAR(255) NOT NULL DEFAULT '', `class_start_date` VARCHAR(64) NOT NULL DEFAULT '',
  `class_end_date` VARCHAR(64) NOT NULL DEFAULT '', `rating_objectives` TINYINT UNSIGNED NULL,
  `rating_trainer` TINYINT UNSIGNED NULL, `rating_environment` TINYINT UNSIGNED NULL,
  `message` TEXT NULL, `source` VARCHAR(64) NOT NULL DEFAULT '', `ip` VARCHAR(64) NOT NULL DEFAULT '',
  `user_agent` VARCHAR(255) NOT NULL DEFAULT '', `status` VARCHAR(16) NOT NULL DEFAULT 'new',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`lead_id`), KEY `IDX_CFB_CREATED` (`created_at`), KEY `IDX_CFB_STATUS` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
