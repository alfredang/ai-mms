-- 1832: page-cache clear log that survives redeploys (Malaysia Step 5 follow-up, partner request 21 Oct 2026).
--   var/log/mmd_fpc.log lives in the container and is wiped on every redeploy (20 Oct: a redeploy erased the
--   00:00/08:00 clear lines before the morning check). MMD_FullPageCache now also writes each clear here.
--   Schema only, safe on every site (SG/GH write nothing while their page cache is off). Idempotent.

CREATE TABLE IF NOT EXISTS `mmd_fpc_log` (
  `log_id`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `created_at` DATETIME     NOT NULL COMMENT 'UTC, like Magento created_at columns',
  `reason`     VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`log_id`),
  KEY `IDX_MMD_FPC_LOG_CREATED_AT` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MMD_FullPageCache: every whole-cache clear and why';
