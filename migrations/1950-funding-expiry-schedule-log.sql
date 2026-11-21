-- Log of schedule-template switches made by the daily funding-expiry job
-- (MMD_Courses_Model_Cron_FundingExpiry, 11:00 store time, Singapore only).
-- A row with restored_at NULL is a funded course currently on its non-WSQ
-- template; the job puts the WSQ template back when the funding is renewed.
CREATE TABLE IF NOT EXISTS mmd_funding_expiry_schedule (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id INT UNSIGNED NOT NULL,
  sku VARCHAR(64) NOT NULL,
  from_group_id INT UNSIGNED NOT NULL,
  from_title VARCHAR(255) NOT NULL,
  to_group_id INT UNSIGNED NOT NULL,
  to_title VARCHAR(255) NOT NULL,
  switched_at DATETIME NOT NULL,
  restored_at DATETIME DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_mmd_funding_expiry_schedule_product (product_id, restored_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
