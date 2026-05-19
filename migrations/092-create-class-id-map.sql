-- mmd_class_id_map: per-store running number for each course session
-- (identified by product_id + course_date). Used to render a stable,
-- human-friendly Class ID on the admin dashboard, formatted like SG000001.
CREATE TABLE IF NOT EXISTS `mmd_class_id_map` (
  `id`          INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  `store_id`    SMALLINT UNSIGNED NOT NULL,
  `product_id`  INT UNSIGNED      NOT NULL,
  `course_date` DATE              NOT NULL,
  `class_no`    INT UNSIGNED      NOT NULL,
  `created_at`  TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_store_product_date` (`store_id`, `product_id`, `course_date`),
  KEY `ix_store_class_no` (`store_id`, `class_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
