-- 1949: admin (backend) speed-up, part 2. Runs on every site; idempotent; no-op branch is 'DO 0'.
--
-- 1. mmd_audit_issues: the nightly scanners re-logged every open finding each night
--    (SG: 1.5M open rows for about 11k distinct findings), so the admin header bell
--    query took 6 s whenever its cache was cold. Keep the NEWEST open row of each
--    finding and delete the older copies. Fixed / dismissed rows are not touched.
--    MMD_Auditfix_Helper_Data::logIssue now refreshes an open finding instead of
--    inserting it again, so the table stays small.
--    (SG was deduped live before this shipped; there this deletes nothing.)
-- 2. admin_user(email): every "find the account for this email" lookup scanned all
--    9,400 SG rows because the queries wrapped the column in LOWER()/TRIM(). The
--    queries now compare the column directly (the collation is case-insensitive) and
--    this adds the index they use. Stored emails are trimmed first so the direct
--    comparison matches exactly what LOWER(TRIM(email)) matched.

DROP TABLE IF EXISTS mmd_audit_issues_keep;

CREATE TABLE mmd_audit_issues_keep (
    issue_id INT UNSIGNED NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

INSERT INTO mmd_audit_issues_keep (issue_id)
SELECT MAX(issue_id)
  FROM mmd_audit_issues
 WHERE status = 'open'
 GROUP BY source, category, severity, title, entity_type, entity_id, store_id;

DELETE a
  FROM mmd_audit_issues a
  LEFT JOIN mmd_audit_issues_keep k ON k.issue_id = a.issue_id
 WHERE a.status = 'open' AND k.issue_id IS NULL;

DROP TABLE IF EXISTS mmd_audit_issues_keep;

-- `created` is ON UPDATE CURRENT_TIMESTAMP on admin_user: keep it.
UPDATE admin_user
   SET email = TRIM(email), created = created
 WHERE email IS NOT NULL AND CHAR_LENGTH(email) <> CHAR_LENGTH(TRIM(email));

SET @has := (SELECT COUNT(*) FROM information_schema.statistics
              WHERE table_schema = DATABASE() AND table_name = 'admin_user'
                AND index_name = 'IDX_ADMIN_USER_EMAIL');
SET @sql := IF(@has = 0,
    'ALTER TABLE admin_user ADD INDEX IDX_ADMIN_USER_EMAIL (email)',
    'DO 0');
PREPARE mms_stmt FROM @sql;
EXECUTE mms_stmt;
DEALLOCATE PREPARE mms_stmt;
