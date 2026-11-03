-- Native learner apps (TC LMS SG / MY / GH) — MMD_MobileApi.
--
-- The web LMS keeps its identity in the adminhtml PHP session; a native app
-- needs a stateless bearer token instead, and an OTP that is not tied to a
-- browser cookie. Neither table holds a secret in clear: tokens and OTP codes
-- are stored as SHA-256 hashes only.
--
-- mmd_mobile_session   one row per signed-in device; revoked on sign-out /
--                      account deletion, expires after inactivity.
-- mmd_mobile_otp       one row per emailed code; single use, 10-minute expiry,
--                      5 wrong guesses burn it.
-- mmd_mobile_feedback  which learner answered the in-house survey for which
--                      class — the public /feedback form is anonymous, the app
--                      is not, so the app can show "submitted" and stop
--                      duplicate responses. review_id points at the Magento
--                      review the answer was saved as (the single feedback store).
--
-- Runs identically on SG, MY and GH (no @mms_instance branching).

CREATE TABLE IF NOT EXISTS `mmd_mobile_session` (
    `session_id`    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `token_hash`    CHAR(64)      NOT NULL COMMENT 'sha256 of the bearer token',
    `email`         VARCHAR(255)  NOT NULL COMMENT 'lower-case learner email',
    `customer_id`   INT UNSIGNED  NULL     COMMENT 'customer_entity.entity_id when known',
    `is_demo`       TINYINT(1)    NOT NULL DEFAULT 0 COMMENT 'App Review account: sample data only',
    `platform`      VARCHAR(16)   NULL     COMMENT 'ios / android',
    `app_version`   VARCHAR(32)   NULL,
    `created_at`    DATETIME      NOT NULL,
    `last_used_at`  DATETIME      NOT NULL,
    `expires_at`    DATETIME      NOT NULL,
    `revoked_at`    DATETIME      NULL,
    PRIMARY KEY (`session_id`),
    UNIQUE KEY `uk_token_hash` (`token_hash`),
    KEY `idx_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mmd_mobile_otp` (
    `otp_id`        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `email`         VARCHAR(255)  NOT NULL,
    `code_hash`     CHAR(64)      NOT NULL COMMENT 'sha256(email|code)',
    `attempts`      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `ip`            VARCHAR(64)   NULL,
    `created_at`    DATETIME      NOT NULL,
    `expires_at`    DATETIME      NOT NULL,
    `consumed_at`   DATETIME      NULL,
    PRIMARY KEY (`otp_id`),
    KEY `idx_email_created` (`email`, `created_at`),
    KEY `idx_ip_created` (`ip`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mmd_mobile_feedback` (
    `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `run_id`        INT UNSIGNED  NOT NULL,
    `learner_email` VARCHAR(255)  NOT NULL,
    `review_id`     INT UNSIGNED  NULL,
    `created_at`    DATETIME      NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_run_learner` (`run_id`, `learner_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- App Review sign-in (Apple / Google). The reviewer account has no customer
-- record: it signs in with a password checked against this bcrypt hash and
-- sees sample data only (MMD_MobileApi_Helper_Demo). The hash is of a long
-- random password kept out of this repo (it goes only into the private App
-- Store / Play review notes), so publishing the hash exposes nothing usable.
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'mmd_mobileapi/general/demo_password_hash', '$2y$12$OfJTAO3oHtOj/FuBTO.pIu22YjFYYI5DqNtHUZIjCSoeoRzOhCS3e')
ON DUPLICATE KEY UPDATE value = VALUES(value);
