-- Integration metadata; no existing funded-course records are modified.
CREATE TABLE IF NOT EXISTS mmd_tms_run_link (
  link_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  provider_id VARCHAR(64) NOT NULL,
  source_run_key VARCHAR(255) NOT NULL,
  run_id INT UNSIGNED NOT NULL,
  course_code VARCHAR(64) NOT NULL,
  revision BIGINT UNSIGNED NOT NULL,
  snapshot_hash CHAR(64) NOT NULL,
  active TINYINT NOT NULL DEFAULT 1,
  sessions_json MEDIUMTEXT NOT NULL,
  feedback_url VARCHAR(1000) NOT NULL DEFAULT '',
  result_json MEDIUMTEXT NULL,
  synced_at DATETIME NOT NULL,
  UNIQUE KEY uk_source (provider_id,source_run_key),
  UNIQUE KEY uk_target (run_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS mmd_tms_event_link (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  link_id INT UNSIGNED NOT NULL,
  calendar_id VARCHAR(255) NOT NULL,
  event_id VARCHAR(255) NOT NULL,
  identity_hash CHAR(64) NOT NULL,
  UNIQUE KEY uk_event (identity_hash),
  KEY idx_link (link_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS mmd_tms_person_link (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  provider_id VARCHAR(64) NOT NULL,
  source_id VARCHAR(255) NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  email VARCHAR(128) NOT NULL,
  UNIQUE KEY uk_person (provider_id,source_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS mmd_tms_member_link (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  link_id INT UNSIGNED NOT NULL,
  source_id VARCHAR(255) NOT NULL,
  email VARCHAR(128) NOT NULL,
  role_code VARCHAR(32) NOT NULL,
  active TINYINT NOT NULL DEFAULT 1,
  import_owned TINYINT NOT NULL DEFAULT 0,
  independent_membership TINYINT NOT NULL DEFAULT 0,
  UNIQUE KEY uk_member (link_id,source_id,role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS mmd_tms_sync_log (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  provider_id VARCHAR(64) NOT NULL,
  source_run_key VARCHAR(255) NOT NULL,
  revision BIGINT UNSIGNED NOT NULL,
  result_json MEDIUMTEXT NOT NULL,
  created_at DATETIME NOT NULL,
  KEY idx_source (provider_id,source_run_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
