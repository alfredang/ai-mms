-- 325: Enquiry stores for the two new Enquiries partnership lead magnets —
--      MMD_Sctp (SSG Career Transition Programme development) and
--      MMD_Wpl (Workplace Learning development). Both mirror mmd_coursedev_lead
--      (migration 321). Harmless empty tables on partner DBs (the modules deploy
--      everywhere; only SG links the forms).
CREATE TABLE IF NOT EXISTS `mmd_sctp_lead` (
  `lead_id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `store_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `store_code` VARCHAR(32) NOT NULL DEFAULT '', `name` VARCHAR(255) NOT NULL DEFAULT '',
  `email` VARCHAR(255) NOT NULL DEFAULT '', `telephone` VARCHAR(64) NOT NULL DEFAULT '',
  `company` VARCHAR(255) NOT NULL DEFAULT '', `expertise` VARCHAR(255) NOT NULL DEFAULT '',
  `message` TEXT NULL, `source` VARCHAR(64) NOT NULL DEFAULT '', `ip` VARCHAR(64) NOT NULL DEFAULT '',
  `user_agent` VARCHAR(255) NOT NULL DEFAULT '', `status` VARCHAR(16) NOT NULL DEFAULT 'new',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`lead_id`), KEY `IDX_SCTP_CREATED` (`created_at`), KEY `IDX_SCTP_STATUS` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mmd_wpl_lead` (
  `lead_id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `store_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `store_code` VARCHAR(32) NOT NULL DEFAULT '', `name` VARCHAR(255) NOT NULL DEFAULT '',
  `email` VARCHAR(255) NOT NULL DEFAULT '', `telephone` VARCHAR(64) NOT NULL DEFAULT '',
  `company` VARCHAR(255) NOT NULL DEFAULT '', `expertise` VARCHAR(255) NOT NULL DEFAULT '',
  `message` TEXT NULL, `source` VARCHAR(64) NOT NULL DEFAULT '', `ip` VARCHAR(64) NOT NULL DEFAULT '',
  `user_agent` VARCHAR(255) NOT NULL DEFAULT '', `status` VARCHAR(16) NOT NULL DEFAULT 'new',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`lead_id`), KEY `IDX_WPL_CREATED` (`created_at`), KEY `IDX_WPL_STATUS` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
