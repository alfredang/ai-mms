-- 849: Track which learner emails have been submitted to a MailerLite
-- subscriber group from the Manage Learners admin page. One row per email;
-- drives the read-only "submitted" checkbox in the learner grid and lets
-- re-submits stay idempotent. Pure DDL, idempotent, partner-safe (same
-- table on SG/MY/GH — no data pulled from legacy tables).
CREATE TABLE IF NOT EXISTS `mmd_learner_mailerlite` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(255) NOT NULL,
  `group_id` VARCHAR(32) NOT NULL,
  `store_code` VARCHAR(8) NOT NULL DEFAULT '',
  `submitted_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
