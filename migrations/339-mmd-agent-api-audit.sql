-- Audit trail for every OpenClaw agent write/commit through MMD_AgentApi.
-- One row per committed change: which chat user (WhatsApp number + name + role)
-- asked, what capability/op, the target, the before/after, and the plain-English
-- summary the user approved. Idempotent (CREATE TABLE IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS `mmd_agent_api_audit` (
    `audit_id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `actor_wa_number`  VARCHAR(32)  NOT NULL,
    `actor_name`       VARCHAR(128) NULL,
    `actor_role`       VARCHAR(64)  NULL,
    `capability`       VARCHAR(32)  NOT NULL,
    `op`               VARCHAR(48)  NOT NULL,
    `target`           VARCHAR(128) NULL,
    `before_json`      MEDIUMTEXT   NULL,
    `after_json`       MEDIUMTEXT   NULL,
    `human_summary`    TEXT         NULL,
    `result`           VARCHAR(32)  NOT NULL DEFAULT 'applied',
    `ip`               VARCHAR(64)  NULL,
    `created_at`       DATETIME     NOT NULL,
    PRIMARY KEY (`audit_id`),
    KEY `idx_actor`   (`actor_wa_number`),
    KEY `idx_cap_op`  (`capability`, `op`),
    KEY `idx_target`  (`target`),
    KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
