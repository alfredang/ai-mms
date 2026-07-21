-- 634: Delete three partner-contact admin accounts from the SG install.
--
-- WHY
-- Under the franchise model each partner runs their own server + DB, so a
-- Malaysia / Ghana / Nigeria contact has no reason to hold an operator account
-- on the Singapore install. All three carried the full six-role set (admin,
-- developer, marketing, learner, trainer, training_provider), which also put
-- them in the Edit Course trainer picker and made them invitable for SG
-- classes they would never teach.
--
--   saeid@tertiarycourses.com.my       Malaysia  (271 logins, last 2026-04-01)
--   siraj@tertiarycourses.com.gh       Ghana     (never logged in)
--   info.tertiarycourses.ng@gmail.com  Nigeria   (retired store, never logged in)
--
-- Verified before writing: none of the three owns any row in
-- mmd_product_trainer, course_runs.trainer_user_id or
-- course_run_trainer_invitations, so no class loses its trainer and no
-- invitation is orphaned.
--
-- NOTE ON SCOPE
-- This removes the accounts from THIS install only. Each partner keeps their
-- own admin account on their own server — deleting an SG row cannot and does
-- not affect the MY or GH sites.
--
-- PARTNER-SAFE
-- Matched by email, never user_id (ids differ per server). admin_user has no
-- inbound FK constraints in this schema, so the dependent rows in
-- mmd_user_role_map / admin_role / mmd_product_trainer are cleared explicitly
-- rather than relying on ON DELETE CASCADE. Every statement is guarded on
-- table existence and is re-runnable (a second run deletes nothing).
--
-- Deliberately NOT included: the seeded admin.*@example.com country admins.
-- Those are a separate decision (several are for retired stores and are still
-- active with placeholder credentials) and should get their own migration.

-- SG-ONLY. The runner exposes the container's MMS_COUNTRY_CODE as
-- @mms_instance. This delete is matched by email, and saeid@tertiarycourses.com.my
-- is the Malaysia PARTNER'S OWN working admin account on the MY server — running
-- this unguarded would lock them out of their own site. On any non-SG instance
-- @emails is blank, so every FIND_IN_SET below matches nothing and the whole
-- migration is a no-op.
SET @emails := IF(@mms_instance = 'SG',
  'saeid@tertiarycourses.com.my,siraj@tertiarycourses.com.gh,info.tertiarycourses.ng@gmail.com',
  '');

-- 1. Per-course trainer pool entries (guarded: table is RoleManager-specific).
SET @has_pt := (SELECT COUNT(*) FROM information_schema.TABLES
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_product_trainer');
SET @sql := IF(@has_pt > 0,
  'DELETE pt FROM mmd_product_trainer pt JOIN admin_user u ON u.user_id = pt.user_id
    WHERE FIND_IN_SET(u.email, @emails)',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 2. Custom role map.
SET @has_map := (SELECT COUNT(*) FROM information_schema.TABLES
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_user_role_map');
SET @sql := IF(@has_map > 0,
  'DELETE m FROM mmd_user_role_map m JOIN admin_user u ON u.user_id = m.user_id
    WHERE FIND_IN_SET(u.email, @emails)',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 3. Magento ACL role rows (admin_role.user_id, user_type = 2 for users).
DELETE r FROM admin_role r JOIN admin_user u ON u.user_id = r.user_id
 WHERE FIND_IN_SET(u.email, @emails);

-- 4. The accounts themselves.
DELETE FROM admin_user WHERE FIND_IN_SET(email, @emails);
