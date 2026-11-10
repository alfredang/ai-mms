-- Availability is owned by TMS/SSG and pushed into this cache. Products remain
-- enabled so their direct URL can explain a pending renewal, while visibility
-- and salability are controlled by the synchronized status.
CREATE TABLE IF NOT EXISTS mmd_course_availability (
  product_id INT UNSIGNED NOT NULL,
  course_code VARCHAR(64) NOT NULL,
  ssg_course_code VARCHAR(64) DEFAULT NULL,
  availability_status VARCHAR(32) NOT NULL,
  availability_reason VARCHAR(255) DEFAULT NULL,
  support_from DATE DEFAULT NULL,
  support_to DATE DEFAULT NULL,
  has_future_run TINYINT(1) NOT NULL DEFAULT 0,
  checked_at DATETIME NOT NULL,
  original_visibility SMALLINT UNSIGNED DEFAULT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (product_id),
  KEY idx_mmd_course_availability_code (course_code),
  KEY idx_mmd_course_availability_status (availability_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
