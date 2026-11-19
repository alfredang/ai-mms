-- Native apps (TC LMS SG / MY / GH) 1.4 - MMD_MobileApi.
--
-- mmd_mobile_profile  per-account settings the apps read and write through
--                     /mobileapi/profile: the appearance (system / light /
--                     dark) both phones follow, and a phone number for an
--                     account that has no dashboard record to hold one.
--
-- Runs identically on every site (no @mms_instance branching).

CREATE TABLE IF NOT EXISTS `mmd_mobile_profile` (
    `email`       VARCHAR(255) NOT NULL COMMENT 'lower-case account email',
    `theme`       VARCHAR(8)   NOT NULL DEFAULT 'system' COMMENT 'system / light / dark',
    `phone`       VARCHAR(32)  NULL,
    `updated_at`  DATETIME     NOT NULL,
    PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
