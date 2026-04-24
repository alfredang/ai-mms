-- Per-session (course_date option_type_value) trainer assignments.
-- Magento's native custom options don't support extra metadata per option value,
-- so we map option_type_id -> trainer option from the `trainers` EAV attribute.
CREATE TABLE IF NOT EXISTS `course_session_trainers` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `option_type_id` INT UNSIGNED NOT NULL COMMENT 'catalog_product_option_type_value.option_type_id (one session)',
    `trainer_option_id` INT UNSIGNED NOT NULL COMMENT 'eav_attribute_option.option_id on the trainers attribute',
    `trainer_name` VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Cached display name for lists',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `UQ_option_type_id` (`option_type_id`),
    KEY `IDX_trainer_option_id` (`trainer_option_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='One trainer per course session/date option value';
