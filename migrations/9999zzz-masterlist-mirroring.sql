-- Source aliases share one existing course_runs class (SKU + start/end dates).
CREATE TABLE IF NOT EXISTS mmd_tms_source_alias (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  provider_id VARCHAR(64) NOT NULL,
  source_run_key VARCHAR(255) NOT NULL,
  link_id INT UNSIGNED NOT NULL,
  revision BIGINT UNSIGNED NOT NULL DEFAULT 0,
  snapshot_hash CHAR(64) NOT NULL DEFAULT '',
  UNIQUE KEY uk_source (provider_id,source_run_key),
  KEY idx_link (link_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
