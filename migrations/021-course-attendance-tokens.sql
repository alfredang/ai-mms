-- E-Attendance check-in tokens. Trainer generates a token per session;
-- learners open the resulting URL while logged in (customer) to check themselves in.
CREATE TABLE IF NOT EXISTS `course_attendance_tokens` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `token` VARCHAR(40) NOT NULL COMMENT 'Unguessable URL-safe token',
    `code` VARCHAR(10) NOT NULL DEFAULT '' COMMENT 'Short human-readable code for verbal sharing',
    `product_id` INT UNSIGNED NOT NULL,
    `option_type_id` INT UNSIGNED NOT NULL COMMENT 'Session (catalog_product_option_type_value.option_type_id)',
    `created_by_admin_id` INT UNSIGNED NULL,
    `expires_at` TIMESTAMP NULL DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `UQ_token` (`token`),
    KEY `IDX_option_type_id` (`option_type_id`),
    KEY `IDX_code_active` (`code`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='E-Attendance check-in tokens, one row per session generation';
