-- 633: Admin accounts are not trainers — strip role_code='trainer' from the
-- seeded country-admin users.
--
-- WHY
-- The Edit Course > Trainer Details picker lists every admin_user carrying the
-- 'trainer' role. The six seeded country-admin accounts (admin.sg / .my / .gh /
-- .ng / .bt / .in @example.com) were created with ALL SIX roles, so they showed
-- up as selectable "trainers" alongside real people. Three of them are for
-- retired stores (NG / BT / IN) and every one of them carries a placeholder
-- @example.com address, so a trainer invitation sent to one silently goes
-- nowhere — the invite queue would stall on a trainer who can never reply.
--
-- SCOPE
-- Only the 'trainer' row is deleted. These accounts keep admin / developer /
-- marketing / learner / training_provider, so their admin access is untouched.
--
-- PARTNER-SAFE
-- Matched by email pattern + role, never by user_id: the same seeded admins
-- exist on the MY and GH servers under different ids. Guarded on table
-- existence so it is a no-op on any instance without mmd_user_role_map.
-- Re-runnable: a second run deletes nothing.

SET @has_map := (SELECT COUNT(*) FROM information_schema.TABLES
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_user_role_map');

SET @sql := IF(@has_map > 0,
  'DELETE m FROM mmd_user_role_map m
     JOIN admin_user u ON u.user_id = m.user_id
    WHERE m.role_code = ''trainer''
      AND u.email LIKE ''admin.%@example.com''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Drop any course-pool assignment those accounts may already hold, so a
-- previously-saved pool cannot keep pointing at a non-trainer.
SET @has_pt := (SELECT COUNT(*) FROM information_schema.TABLES
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_product_trainer');

SET @sql2 := IF(@has_pt > 0,
  'DELETE pt FROM mmd_product_trainer pt
     JOIN admin_user u ON u.user_id = pt.user_id
    WHERE u.email LIKE ''admin.%@example.com''',
  'SELECT 1');
PREPARE stmt2 FROM @sql2; EXECUTE stmt2; DEALLOCATE PREPARE stmt2;
