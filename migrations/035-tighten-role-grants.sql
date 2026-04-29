-- Tighten ACL grants for Learner / Trainer / Marketing.
--
-- The original install-1.0.0.php seeded these groups with `admin/catalog`
-- which lets them reach Manage Categories / Manage Products / URL Rewrite /
-- Search Terms / Reviews / Subjects / Sitemap — none of which are
-- appropriate for those roles in an LMS:
--
--   Learner:  views their own enrolled courses (the custom dashboard,
--             which only requires admin/dashboard). Has no business in
--             catalog admin.
--   Trainer:  teaches classes. Tracks attendance + their students' orders.
--             Doesn't manage products/categories.
--   Marketing: manages campaigns, CMS pages, and promotions. Doesn't
--              manage the course catalog itself — that's the Developer /
--              Admin / Training Provider roles.
--
-- Wipe each of the three groups' rules, then re-seed only what each role
-- actually needs. role_type='G' is set on insert (see migration 032 for
-- why this matters).

DELETE ru FROM admin_rule ru
JOIN admin_role r ON r.role_id = ru.role_id
WHERE r.role_type = 'G'
  AND r.role_name IN ('Learner', 'Trainer', 'Marketing');

SET @learner_id   := (SELECT role_id FROM admin_role WHERE role_name='Learner'   AND role_type='G' LIMIT 1);
SET @trainer_id   := (SELECT role_id FROM admin_role WHERE role_name='Trainer'   AND role_type='G' LIMIT 1);
SET @marketing_id := (SELECT role_id FROM admin_role WHERE role_name='Marketing' AND role_type='G' LIMIT 1);

INSERT INTO admin_rule (role_id, resource_id, role_type, privileges, permission)
SELECT t.role_id, t.resource_id, 'G', NULL, 'allow'
FROM (
    -- Learner: just the dashboard. Their custom dashboard renders within
    -- /adminhtml/dashboard which only requires admin/dashboard.
    SELECT @learner_id AS role_id, 'admin/dashboard' AS resource_id
    -- Trainer: dashboard for their class panel, plus sales/order so they
    -- can see who's enrolled, plus reports.
    UNION ALL SELECT @trainer_id,   'admin/dashboard'
    UNION ALL SELECT @trainer_id,   'admin/sales'
    UNION ALL SELECT @trainer_id,   'admin/sales/order'
    UNION ALL SELECT @trainer_id,   'admin/report'
    -- Marketing: campaigns + CMS + promotions only. NO catalog.
    UNION ALL SELECT @marketing_id, 'admin/dashboard'
    UNION ALL SELECT @marketing_id, 'admin/promo'
    UNION ALL SELECT @marketing_id, 'admin/cms'
) t
WHERE t.role_id IS NOT NULL;
