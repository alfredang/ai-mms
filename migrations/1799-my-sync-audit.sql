-- Malaysia-aware SG -> Malaysia sync: dry-run report, audit and rollback log.
-- One row per sync run (planned dry-run -> applied -> rolled back) and one row per planned
-- change, with the exact before value of every store row so a run can be rolled back.
-- Populated by MMD_RoleManager_Model_Sync_MalaysiaSync (Malaysia site only). Empty, unused
-- tables on other sites. Idempotent.

CREATE TABLE IF NOT EXISTS `mmd_my_sync_run` (
    `run_id`       INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `op`           VARCHAR(16)  NOT NULL COMMENT 'courses | categories',
    `scope`        VARCHAR(64)  NULL     COMMENT 'single course SKU, NULL = full',
    `status`       ENUM('planned','applied','rolled_back','superseded') NOT NULL DEFAULT 'planned',
    `planned_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `planned_by`   VARCHAR(128) NULL,
    `applied_at`   DATETIME     NULL,
    `applied_by`   VARCHAR(128) NULL,
    `rolled_back_at` DATETIME   NULL,
    `rolled_back_by` VARCHAR(128) NULL,
    `summary`      TEXT         NULL COMMENT 'JSON counts',
    PRIMARY KEY (`run_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mmd_my_sync_change` (
    `change_id`   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `run_id`      INT UNSIGNED NOT NULL,
    `seq`         INT UNSIGNED NOT NULL DEFAULT 0,
    `entity`      VARCHAR(16)  NOT NULL COMMENT 'product | category',
    `entity_id`   INT UNSIGNED NULL,
    `ref`         VARCHAR(255) NOT NULL COMMENT 'SKU or category URL key',
    `kind`        VARCHAR(24)  NOT NULL COMMENT 'attr | categories | create | redirect | notice',
    `field`       VARCHAR(64)  NULL,
    `old_value`   LONGTEXT     NULL COMMENT 'JSON: store_id => value (attr), list (categories), path (redirect)',
    `new_value`   LONGTEXT     NULL,
    `outcome`     VARCHAR(32)  NULL COMMENT 'applied | conflict | rolled_back | error: ...',
    PRIMARY KEY (`change_id`),
    KEY `idx_run` (`run_id`, `seq`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
