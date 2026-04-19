-- Backfill: ensure every admin_user row has all 6 role_code entries in
-- mmd_user_role_map. Covers users created after migration 014 ran (so their
-- roles were never seeded) and any role rows that were manually deleted.
-- Idempotent: INSERT IGNORE skips existing (user_id, role_code) pairs.
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

-- Any user still without a primary role gets 'admin' promoted, so the
-- login observer has a default to pick.
UPDATE mmd_user_role_map m
INNER JOIN (
    SELECT DISTINCT u.user_id
    FROM admin_user u
    LEFT JOIN mmd_user_role_map p ON p.user_id = u.user_id AND p.is_primary = 1
    WHERE p.user_id IS NULL
) no_primary ON no_primary.user_id = m.user_id
SET m.is_primary = 1
WHERE m.role_code = 'admin';
