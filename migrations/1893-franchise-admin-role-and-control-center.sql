-- 1893: Franchise Admin role + Franchise Control Center storage.
--
-- WHY: the AI-MMS is a franchise system — SG is the control site, MY/GH are
-- franchisees. The new "Franchise Admin" role owns the control center
-- (all-franchise stats, syncs, fee collection); the existing training_provider
-- role (now labelled "Training Provider") manages ONE site only.
--
-- 1. ACL group "Franchise Admin" (role_type='G', all=allow — same grant model
--    as migration 065; the functional gate is RoleManager's _roleControllerMap).
-- 2. Assign the franchise_admin role ONLY to angch@tertiaryinfotech.com, and
--    only on the SG control site (the control center is SG-only).
-- 3. Storage pulled daily from every site (SG local + MY/GH over
--    /courses/api_franchise_stats): classes, registrations, fee ledger.
--    Created on every instance (harmless empty tables on partners).
-- 4. Fee defaults: MY no franchise fee; GH USD 20 per billable learner per
--    delivered class.
-- Idempotent throughout.

INSERT INTO admin_role (parent_id, tree_level, sort_order, role_type, user_id, role_name)
SELECT 0, 1, 0, 'G', 0, 'Franchise Admin'
WHERE NOT EXISTS (SELECT 1 FROM admin_role WHERE role_name = 'Franchise Admin' AND role_type = 'G');

SET @fa_role_id := (SELECT role_id FROM admin_role WHERE role_name = 'Franchise Admin' AND role_type = 'G' LIMIT 1);

INSERT INTO admin_rule (role_id, resource_id, role_type, privileges, permission)
SELECT @fa_role_id, 'all', 'G', NULL, 'allow'
WHERE @fa_role_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM admin_rule WHERE role_id = @fa_role_id AND resource_id = 'all');

-- Only Alfred gets the role, only on the SG control site.
SET @fa_user_id := (SELECT user_id FROM admin_user WHERE email = 'angch@tertiaryinfotech.com' LIMIT 1);
INSERT INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT @fa_user_id, 'franchise_admin', 0, NOW()
WHERE @fa_user_id IS NOT NULL AND @mms_instance = 'SG'
  AND NOT EXISTS (SELECT 1 FROM mmd_user_role_map WHERE user_id = @fa_user_id AND role_code = 'franchise_admin');

CREATE TABLE IF NOT EXISTS mmd_franchise_classes (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    source_country VARCHAR(8) NOT NULL,
    class_code VARCHAR(20) NOT NULL,
    course_code VARCHAR(64) NOT NULL DEFAULT '',
    course_title VARCHAR(255) NOT NULL DEFAULT '',
    start_date DATE NULL,
    end_date DATE NULL,
    trainer_name VARCHAR(255) NOT NULL DEFAULT '',
    status VARCHAR(16) NOT NULL DEFAULT 'upcoming' COMMENT 'upcoming | confirmed | completed',
    enrolled INT UNSIGNED NOT NULL DEFAULT 0,
    attended INT UNSIGNED NOT NULL DEFAULT 0,
    certs_issued INT UNSIGNED NOT NULL DEFAULT 0,
    pulled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_country_class (source_country, class_code),
    KEY idx_start (start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS mmd_franchise_orders (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    source_country VARCHAR(8) NOT NULL,
    order_no VARCHAR(50) NOT NULL,
    item_id INT UNSIGNED NOT NULL DEFAULT 0,
    ordered_at DATETIME NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT '',
    course_code VARCHAR(64) NOT NULL DEFAULT '',
    course_title VARCHAR(255) NOT NULL DEFAULT '',
    class_date DATE NULL,
    learners INT UNSIGNED NOT NULL DEFAULT 1,
    amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency CHAR(3) NOT NULL DEFAULT '',
    pulled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_country_order_item (source_country, order_no, item_id),
    KEY idx_ordered (ordered_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS mmd_franchise_class_fee (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    source_country VARCHAR(8) NOT NULL,
    class_code VARCHAR(20) NOT NULL,
    course_code VARCHAR(64) NOT NULL DEFAULT '',
    course_title VARCHAR(255) NOT NULL DEFAULT '',
    start_date DATE NULL,
    billable_learners INT UNSIGNED NOT NULL DEFAULT 0,
    unit_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    status VARCHAR(16) NOT NULL DEFAULT 'pending' COMMENT 'pending | completed',
    paid_at DATETIME NULL,
    paid_by VARCHAR(255) NULL,
    note VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_country_class (source_country, class_code),
    KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO core_config_data (scope, scope_id, path, value) VALUES
    ('default', 0, 'mmd/franchise_fee/my_per_learner', '0'),
    ('default', 0, 'mmd/franchise_fee/my_currency', 'USD'),
    ('default', 0, 'mmd/franchise_fee/gh_per_learner', '20'),
    ('default', 0, 'mmd/franchise_fee/gh_currency', 'USD');
