-- Per-learner Trainee Particulars so the Enroll Learners form can auto-fill
-- every field (not just email + name) when an admin picks an existing learner.
--
-- Keyed by email (canonical identifier — an admin_user and a customer_entity
-- with the same email still share one profile). customer_id is optional
-- because Magento customers are created lazily at enrolment time.
CREATE TABLE IF NOT EXISTS `learner_profile` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `email` VARCHAR(255) NOT NULL,
    `customer_id` INT UNSIGNED NULL,
    `id_type` VARCHAR(32) NOT NULL DEFAULT 'NRIC',
    `nric` VARCHAR(64) NOT NULL DEFAULT '',
    `full_name` VARCHAR(255) NOT NULL DEFAULT '',
    `date_of_birth` DATE NULL,
    `country_code` VARCHAR(8) NOT NULL DEFAULT '+65',
    `phone_number` VARCHAR(32) NOT NULL DEFAULT '',
    `sponsorship_type` VARCHAR(32) NOT NULL DEFAULT 'INDIVIDUAL',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `UQ_email` (`email`),
    KEY `IDX_customer_id` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Trainee particulars remembered across enrolments';
