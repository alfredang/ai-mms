-- Manual attendance records, keyed by (session, learner).
-- One row per learner per session; overwrite on re-mark.
CREATE TABLE IF NOT EXISTS `course_attendance` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `option_type_id` INT UNSIGNED NOT NULL COMMENT 'catalog_product_option_type_value.option_type_id (the session)',
    `customer_id` INT UNSIGNED NOT NULL COMMENT 'Magento customer (learner) id',
    `status` ENUM('present','absent') NOT NULL DEFAULT 'absent',
    `marked_by_admin_id` INT UNSIGNED NULL COMMENT 'admin_user.user_id who marked this',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `UQ_session_customer` (`option_type_id`,`customer_id`),
    KEY `IDX_customer` (`customer_id`),
    KEY `IDX_option_type` (`option_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Manual attendance per learner per session';
