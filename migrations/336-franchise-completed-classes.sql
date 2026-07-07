-- 336: Local store for completed classes pulled from franchise partners
-- (MY/GH). Filled by the weekly Sunday-10am cron (FranchiseClassesPull) and
-- the Super Admin "Pull Now" button; displayed in the Super Admin dashboard
-- "Franchisee Completed Classes" card. One row per (source_country,
-- class_code); re-pulls upsert so counts stay current. Created on every
-- instance (harmless empty table on partners — the pull cron is SG-only).
CREATE TABLE IF NOT EXISTS mmd_franchise_completed_classes (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    source_country VARCHAR(8) NOT NULL,
    class_code VARCHAR(20) NOT NULL,
    course_title VARCHAR(255) NOT NULL DEFAULT '',
    course_code VARCHAR(64) NOT NULL DEFAULT '',
    start_date DATE NULL,
    end_date DATE NULL,
    trainer_name VARCHAR(255) NOT NULL DEFAULT '',
    learners_attended INT UNSIGNED NOT NULL DEFAULT 0,
    pulled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_country_class (source_country, class_code),
    KEY idx_start_date (start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
