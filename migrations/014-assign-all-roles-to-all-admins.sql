-- Give every admin user all 6 roles (Learner, Trainer, Developer, Marketing,
-- Admin, Super Admin). INSERT IGNORE preserves existing is_primary flags.
CREATE TABLE IF NOT EXISTS mmd_user_role_map (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id MEDIUMINT(8) UNSIGNED NOT NULL,
    role_code VARCHAR(32) NOT NULL,
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY UNQ_USER_ROLE (user_id, role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO mmd_user_role_map (user_id, role_code, is_primary, created_at)
SELECT u.user_id, r.code, 0, NOW()
FROM admin_user u
CROSS JOIN (
    SELECT 'learner' AS code UNION ALL
    SELECT 'trainer' UNION ALL
    SELECT 'developer' UNION ALL
    SELECT 'marketing' UNION ALL
    SELECT 'admin' UNION ALL
    SELECT 'training_provider'
) r;

-- Users without any primary role: promote their 'admin' entry to primary
-- so the observer can pick a default at login.
UPDATE mmd_user_role_map m
INNER JOIN (
    SELECT DISTINCT u.user_id
    FROM admin_user u
    LEFT JOIN mmd_user_role_map p ON p.user_id = u.user_id AND p.is_primary = 1
    WHERE p.user_id IS NULL
) no_primary ON no_primary.user_id = m.user_id
SET m.is_primary = 1
WHERE m.role_code = 'admin';
