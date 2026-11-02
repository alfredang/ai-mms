-- SG checkout "Funding/Payment Information" radio list (user directive 2026-10-30):
--   1. first item  -> "WSQ/CASL/SFC (Only for SWDA funded courses)"   (payment/cheque/title)
--   2. new item after IBF-STS -> "SFEC (Only for company sponsored)"  (new RS_Sfec method, code 'sfec')
-- sfec ships inactive by default (RS_Sfec/etc/config.xml); it is switched on here for SG only.
-- sort_order 3.5 slots it between citrep (3) and purchaseorder (4) without renumbering the others.
-- SG-guarded (store guard); no PREPARE/EXECUTE, so nothing to leave unread on partner DBs.
-- Idempotent.

SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');

UPDATE core_config_data
   SET value = 'WSQ/CASL/SFC (Only for SWDA funded courses)'
 WHERE @sg = 1 AND scope = 'default' AND scope_id = 0 AND path = 'payment/cheque/title';

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, p.path, p.value FROM (
  SELECT 'payment/sfec/active' AS path, '1' AS value
  UNION ALL SELECT 'payment/sfec/title', 'SFEC (Only for company sponsored)'
  UNION ALL SELECT 'payment/sfec/sort_order', '3.5'
  UNION ALL SELECT 'payment/sfec/order_status', '1'
) p WHERE @sg = 1
ON DUPLICATE KEY UPDATE value = VALUES(value);
