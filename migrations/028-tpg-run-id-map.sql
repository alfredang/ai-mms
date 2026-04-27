-- tpg_run_id_map — official SSG-issued Course Run IDs (e.g. 1089835) mapped to
-- our local product. View Course Run looks here first; the registry is used as
-- secondary, and the hash mapping is the last-resort fallback. Adding rows
-- here is how you teach the system that "Course Run ID X is course Y".
CREATE TABLE IF NOT EXISTS `tpg_run_id_map` (
    `ssg_run_id`        INT UNSIGNED NOT NULL,
    `product_id`        INT UNSIGNED NOT NULL,
    `course_code`       VARCHAR(64) NOT NULL DEFAULT '',
    `created_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`ssg_run_id`),
    KEY `IDX_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='SSG Course Run ID -> local product mapping';

-- Seed: the AI-LMS-TMS reference shows 1089835 -> TGS-2025053209
-- (AWS Certified Data Engineer Associate Training)
INSERT IGNORE INTO tpg_run_id_map (ssg_run_id, product_id, course_code)
SELECT 1089835, e.entity_id, e.sku
FROM catalog_product_entity e
WHERE e.sku = 'TGS-2025053209'
LIMIT 1;
