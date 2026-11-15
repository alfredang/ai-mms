-- C1417 Claude Code Masterclass: approved trainer pool on SG follows its WSQ twin
-- TGS-2025052468 (Agentic AI Applications with Claude Code) (user, 2026-11-15):
--   1. Dr. Alfred Ang  2. Mohan Pothula Rao  3. Teh Siew Yee  4. Tan Woei Ming
-- SG-only (store guard): on MY and GH the approved trainer stays Dr. Alfred Ang alone.
-- Additive and idempotent: only active trainer-role accounts are added, nobody is removed
-- (dropping a pool member would null course_runs.trainer_user_id), existing rows are re-ordered.
-- Applied live on SG on 2026-11-15; on deploy this is a no-op there.

SET @ok := ((SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore') = 1);
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'C1417' LIMIT 1);

INSERT INTO mmd_product_trainer (product_id, user_id, sort_order)
SELECT @pid, u.user_id,
       CASE LOWER(u.email)
            WHEN 'angch@tertiaryinfotech.com' THEN 0
            WHEN 'mohanpothula@gmail.com'     THEN 1
            WHEN 'tehsyee@gmail.com'          THEN 2
            ELSE 3
       END
  FROM admin_user u
  JOIN mmd_user_role_map r ON r.user_id = u.user_id AND r.role_code = 'trainer'
 WHERE @ok AND @pid IS NOT NULL AND u.is_active = 1
   AND LOWER(u.email) IN ('angch@tertiaryinfotech.com', 'mohanpothula@gmail.com',
                          'tehsyee@gmail.com', 'tanwoeiming@gmail.com')
ON DUPLICATE KEY UPDATE sort_order = VALUES(sort_order);
