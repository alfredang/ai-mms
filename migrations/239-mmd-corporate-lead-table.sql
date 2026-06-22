-- 239: Corporate On-Site Training enquiry store for MMD_Corporate.
CREATE TABLE IF NOT EXISTS `mmd_corporate_lead` (
    `lead_id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `store_id`        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `store_code`      VARCHAR(32) NOT NULL DEFAULT '',
    `name`            VARCHAR(255) NOT NULL DEFAULT '',
    `email`           VARCHAR(255) NOT NULL DEFAULT '',
    `telephone`       VARCHAR(64) NOT NULL DEFAULT '',
    `company`         VARCHAR(255) NOT NULL DEFAULT '',
    `num_pax`         VARCHAR(32) NOT NULL DEFAULT '',
    `training_topic`  VARCHAR(255) NOT NULL DEFAULT '',
    `preferred_dates` VARCHAR(128) NOT NULL DEFAULT '',
    `message`         TEXT NULL,
    `source`          VARCHAR(64) NOT NULL DEFAULT '',
    `ip`              VARCHAR(64) NOT NULL DEFAULT '',
    `user_agent`      VARCHAR(255) NOT NULL DEFAULT '',
    `status`          VARCHAR(16) NOT NULL DEFAULT 'new',
    `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`lead_id`),
    KEY `IDX_CORP_LEAD_CREATED` (`created_at`),
    KEY `IDX_CORP_LEAD_STATUS` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
