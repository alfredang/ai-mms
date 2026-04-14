-- MMD_RoleManager's install script created ACL rules without role_type,
-- which makes every rule silently fail during ACL load (role IDs are
-- built as {role_type}{role_id}, so NULL type yields the wrong key).
-- Backfill role_type='G' for any RoleManager rules missing it.

UPDATE admin_rule ar
JOIN admin_role arl ON arl.role_id = ar.role_id
SET ar.role_type = arl.role_type
WHERE ar.role_type IS NULL
  AND arl.role_name IN ('Learner', 'Trainer', 'Admin', 'Super Admin');
