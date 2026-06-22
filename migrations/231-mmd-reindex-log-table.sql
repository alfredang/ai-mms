-- 231: Persistent history of reindex runs for MMD_Reindex. Every scheduled
--      (cron) or manual ("Reindex Now") full reindex writes one row; surfaced
--      in the admin grid System -> Reindex Logs.

CREATE TABLE IF NOT EXISTS `mmd_reindex_log` (
    `log_id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `started_at`       DATETIME NULL,
    `finished_at`      DATETIME NULL,
    `duration_seconds` DECIMAL(8,1) NOT NULL DEFAULT 0,
    `source`           VARCHAR(16) NOT NULL DEFAULT 'cron',
    `status`           VARCHAR(16) NOT NULL DEFAULT 'success',
    `ok_count`         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `fail_count`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `summary`          TEXT NULL,
    `created_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`log_id`),
    KEY `IDX_REINDEX_LOG_CREATED` (`created_at`),
    KEY `IDX_REINDEX_LOG_STATUS` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
