-- Courseware URLs for a course (product). One row per product; overwrite on update.
-- Stored in a dedicated table rather than 11 EAV attributes to keep the
-- catalog_product_entity_* tables tidy and to avoid per-attribute migration churn.
CREATE TABLE IF NOT EXISTS `course_courseware` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` INT UNSIGNED NOT NULL,
    `lesson_plan_url`             VARCHAR(1000) NOT NULL DEFAULT '',
    `learner_guide_url`           VARCHAR(1000) NOT NULL DEFAULT '',
    `facilitator_guide_url`       VARCHAR(1000) NOT NULL DEFAULT '',
    `assessment_plan_url`         VARCHAR(1000) NOT NULL DEFAULT '',
    `learner_slides_url`          VARCHAR(1000) NOT NULL DEFAULT '',
    `trainer_slides_url`          VARCHAR(1000) NOT NULL DEFAULT '',
    `courseware_link`             VARCHAR(1000) NOT NULL DEFAULT '',
    `brochure_link`               VARCHAR(1000) NOT NULL DEFAULT '',
    `skillsfuture_link`           VARCHAR(1000) NOT NULL DEFAULT '',
    `assessment_record_link`      VARCHAR(1000) NOT NULL DEFAULT '',
    `assessment_summary_url`      VARCHAR(1000) NOT NULL DEFAULT '',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `UQ_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Per-product courseware URLs (docs, slides, brochure, etc.)';
