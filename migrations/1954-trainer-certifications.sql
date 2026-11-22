-- Trainer certifications: one list per trainer, edited on the web My Profile
-- (System > My Profile) and in the native apps (Account > My Profile), both
-- through MMD_MobileApi_Helper_Data::saveTrainerCertifications, so the two
-- always show the same list. Keyed by the trainer's lower-case email.
-- Runs identically on every site.

CREATE TABLE IF NOT EXISTS `mmd_trainer_certification` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `email`       VARCHAR(255) NOT NULL,
    `name`        VARCHAR(160) NOT NULL,
    `issuer`      VARCHAR(120) NOT NULL DEFAULT '',
    `year`        SMALLINT UNSIGNED NULL,
    `sort_order`  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `updated_at`  DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_email` (`email`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
