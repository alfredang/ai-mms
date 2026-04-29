-- Add the missing 'Developer' ACL group + rules so applyRoleAcl() has a
-- group to point to for users in the developer role. install-1.0.0.php
-- seeded Learner / Trainer / Admin / Super Admin and upgrade-1.0.0-1.1.0.php
-- added Marketing / Training Provider, but Developer was never created —
-- the role existed only in mmd_user_role_map and Helper/Data.php labels.
--
-- Resources mirror the Developer sidebar in template/page/menu.phtml:
-- Manage Courses / Categories / Attributes / URL Rewrite / Search Terms /
-- Reviews & Ratings / Subjects / Google Sitemap — all live under
-- admin/catalog. admin/system is included so developers can clear the
-- Magento cache / manage indexes from the standard System menu.

INSERT INTO admin_role (parent_id, tree_level, sort_order, role_type, user_id, role_name)
SELECT 0, 1, 0, 'G', 0, 'Developer'
WHERE NOT EXISTS (
    SELECT 1 FROM admin_role WHERE role_name = 'Developer' AND role_type = 'G'
);

SET @dev_role_id := (SELECT role_id FROM admin_role WHERE role_name = 'Developer' AND role_type = 'G' LIMIT 1);

-- role_type='G' is critical: Magento's ACL loader builds role keys as
-- {role_type}{role_id}, so NULL would yield "263" instead of "G263" and
-- every rule would silently fail to attach (see migration 032).
INSERT INTO admin_rule (role_id, resource_id, role_type, privileges, permission)
SELECT @dev_role_id, t.resource_id, 'G', NULL, 'allow'
FROM (
    SELECT 'admin/dashboard' AS resource_id UNION ALL
    SELECT 'admin/catalog'                  UNION ALL
    SELECT 'admin/system'
) t
WHERE NOT EXISTS (
    SELECT 1 FROM admin_rule
    WHERE role_id = @dev_role_id AND resource_id = t.resource_id
);
