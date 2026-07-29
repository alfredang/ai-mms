-- 849: Track the MailerLite submission outcome per learner email from the
-- Manage Learners admin page. One row per email; status drives the
-- MailerLite column in the learner grid:
--   submitted    - pushed to the subscriber group (read-only checked box)
--   excluded     - learner's store has no MailerLite group
--   unsubscribed - MailerLite knows the email as unsubscribed (never re-add)
--   blocked      - MailerLite knows the email as bounced / junk
-- Pure DDL, idempotent, partner-safe (same table on SG/MY/GH — no data
-- pulled from legacy tables).
CREATE TABLE IF NOT EXISTS `mmd_learner_mailerlite` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(255) NOT NULL,
  `group_id` VARCHAR(32) NOT NULL DEFAULT '',
  `store_code` VARCHAR(8) NOT NULL DEFAULT '',
  `status` VARCHAR(16) NOT NULL DEFAULT 'submitted',
  `submitted_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
