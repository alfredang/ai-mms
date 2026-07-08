-- Next-flyer queue for the agentic flyer pipeline: the admin lines up WSQ
-- courses (add / delete / drag-reorder in the Newsletters panel) and the
-- Mon/Thu proposer consumes the TOP row instead of auto-picking a popular
-- class. Safe on every instance (plain CREATE IF NOT EXISTS, no data).
CREATE TABLE IF NOT EXISTS mmd_marketing_flyer_queue (
  queue_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id INT UNSIGNED NOT NULL,
  position INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (queue_id),
  UNIQUE KEY uq_flyer_queue_product (product_id),
  KEY idx_flyer_queue_position (position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
