-- Two changes around the "Orphaned Role Resources" page:
--
-- 1. Admin role gets explicit access to admin/system/acl/orphaned_resources
--    so the controller's _isAllowed() check passes. Admin previously had
--    no admin/system grant at all (only Developer + Super Admin do), so
--    the page returned Access Denied even though Admin is now in our
--    predispatch role-map allow-list.
--
-- 2. Learner / Trainer / Marketing get an EXPLICIT deny on the same
--    resource so the orange notice "The following role resources are no
--    longer available... clicking here" doesn't render in their session.
--    The notice is gated on isAllowed(role, admin/system/acl/orphaned_resources)
--    inside Mage_Admin_Model_Resource_Acl::loadRules. With no rule, Zend_Acl
--    can sometimes resolve through inheritance / fallback paths and return
--    true; an explicit deny is unambiguous.

SET @admin_id     := (SELECT role_id FROM admin_role WHERE role_name='Admin'     AND role_type='G' LIMIT 1);
SET @learner_id   := (SELECT role_id FROM admin_role WHERE role_name='Learner'   AND role_type='G' LIMIT 1);
SET @trainer_id   := (SELECT role_id FROM admin_role WHERE role_name='Trainer'   AND role_type='G' LIMIT 1);
SET @marketing_id := (SELECT role_id FROM admin_role WHERE role_name='Marketing' AND role_type='G' LIMIT 1);

INSERT INTO admin_rule (role_id, resource_id, role_type, privileges, permission)
SELECT t.role_id, 'admin/system/acl/orphaned_resources', 'G', NULL, t.perm
FROM (
    SELECT @admin_id     AS role_id, 'allow' AS perm
    UNION ALL SELECT @learner_id,    'deny'
    UNION ALL SELECT @trainer_id,    'deny'
    UNION ALL SELECT @marketing_id,  'deny'
) t
WHERE t.role_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM admin_rule
      WHERE role_id = t.role_id
        AND resource_id = 'admin/system/acl/orphaned_resources'
  );
