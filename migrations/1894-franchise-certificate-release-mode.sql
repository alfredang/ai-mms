-- 1894: Franchise Control Center — per-franchisee certificate release mode.
--
-- The Franchise Admin decides, per franchisee, whether certificates are sent
-- automatically (the partner's daily 18:30 sweep) or only after the class
-- franchise fee is paid (sweep OFF on the partner; SG releases the class's
-- certificates when its fee is marked completed). Stored on SG and pushed to
-- the partner over /courses/api_franchise_control.
--   Malaysia: auto (no franchise fee).  Ghana: on_payment.
-- The fee ledger records when / how the certificate release went.
-- Idempotent; harmless on partners (SG-side config only).

INSERT IGNORE INTO core_config_data (scope, scope_id, path, value) VALUES
    ('default', 0, 'mmd/franchise_cert/my_mode', 'auto'),
    ('default', 0, 'mmd/franchise_cert/gh_mode', 'on_payment');

SET @fee_col := (SELECT COUNT(*) FROM information_schema.COLUMNS
                  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_franchise_class_fee' AND COLUMN_NAME = 'certs_released_at');
SET @sql := IF(@fee_col = 0,
    'ALTER TABLE mmd_franchise_class_fee ADD COLUMN certs_released_at DATETIME NULL AFTER paid_by, ADD COLUMN certs_note VARCHAR(255) NULL AFTER certs_released_at',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
