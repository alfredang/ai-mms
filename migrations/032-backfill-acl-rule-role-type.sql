-- Migration 006 backfilled admin_rule.role_type='G' for the original 4
-- groups (Learner / Trainer / Admin / Super Admin) created by
-- install-1.0.0.php — without that field, Magento's ACL loader builds the
-- role key as {role_type}{role_id}, so a NULL role_type yields a key like
-- "263" instead of "G263" and every rule silently fails to attach.
--
-- The same INSERT bug existed in upgrade-1.0.0-1.1.0.php (Marketing,
-- Training Provider) and migration 031 (Developer), but 006 only matched
-- the original 4 names. Until now, users in Marketing / Training Provider
-- / Developer have been getting Access Denied on every resource — only
-- the legacy Administrators (id=1) group was working at all.
--
-- This is the generalized fix: backfill role_type from admin_role for
-- ANY rule where it's NULL.

UPDATE admin_rule ar
JOIN admin_role arl ON arl.role_id = ar.role_id
SET ar.role_type = arl.role_type
WHERE ar.role_type IS NULL;
