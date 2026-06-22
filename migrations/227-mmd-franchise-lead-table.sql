-- 227: Franchise-enquiry lead store for MMD_Franchise. Captures submissions from
--      the Regional Franchise Partnership landing page (franchising-application.html)
--      into an admin grid (Marketing -> Franchisee Leads), mirroring mmd_lead.

CREATE TABLE IF NOT EXISTS `mmd_franchise_lead` (
    `lead_id`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `store_id`    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `store_code`  VARCHAR(32) NOT NULL DEFAULT '',
    `name`        VARCHAR(255) NOT NULL DEFAULT '',
    `email`       VARCHAR(255) NOT NULL DEFAULT '',
    `telephone`   VARCHAR(64) NOT NULL DEFAULT '',
    `company`     VARCHAR(255) NOT NULL DEFAULT '',
    `country`     VARCHAR(128) NOT NULL DEFAULT '',
    `message`     TEXT NULL,
    `source`      VARCHAR(64) NOT NULL DEFAULT '',
    `ip`          VARCHAR(64) NOT NULL DEFAULT '',
    `user_agent`  VARCHAR(255) NOT NULL DEFAULT '',
    `status`      VARCHAR(16) NOT NULL DEFAULT 'new',
    `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`lead_id`),
    KEY `IDX_FRANCHISE_LEAD_CREATED` (`created_at`),
    KEY `IDX_FRANCHISE_LEAD_STATUS` (`status`),
    KEY `IDX_FRANCHISE_LEAD_EMAIL` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
