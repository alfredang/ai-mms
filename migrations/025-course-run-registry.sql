-- course_run_registry — tracks which courses have been "created" through
-- TPG Create New Class. Each row gets a sequential run_seq PER WEBSITE so
-- the Trainer/Learner dashboards can render SG-100000, SG-100001, ...
-- regardless of entity_id (course 1434 might be registered first, then
-- course 1057 gets the next number even though its entity_id is lower).
CREATE TABLE IF NOT EXISTS `course_run_registry` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` INT UNSIGNED NOT NULL,
    `website_id` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `run_seq` INT UNSIGNED NOT NULL COMMENT 'Zero-based sequence within website: 0=100000, 1=100001, ...',
    `registered_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `UQ_product_id` (`product_id`),
    KEY `IDX_website_seq` (`website_id`, `run_seq`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Per-course run sequence for TPG-created classes';

-- Backfill: courses the admin already created via TPG before this table existed.
-- Order matches their creation order so C1434 (first) gets SG-100000.
INSERT IGNORE INTO course_run_registry (product_id, website_id, run_seq, registered_at) VALUES
    (1434, 1, 0, NOW()),
    (1317, 1, 1, NOW()),
    (1057, 1, 2, NOW());
