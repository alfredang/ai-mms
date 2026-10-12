-- 1812: make the PSG-SFTS.html 301 from 1811 actually match.
--
-- WHY: Mage_Core_Model_Resource_Url_Rewrite::loadByRequestPath() lowercases the
-- requested path and then only accepts rows whose request_path is already lowercase
-- (array_change_key_case on the penalty map). 1811 stored 'PSG-SFTS.html' mixed-case,
-- so it never matched and the URL kept returning 404. Stored lowercase, it serves both
-- /PSG-SFTS.html and /psg-sfts.html. SG only via the gsc404- id_path; idempotent.

UPDATE core_url_rewrite
   SET request_path = LOWER(request_path)
 WHERE id_path LIKE 'gsc404-%'
   AND BINARY request_path <> LOWER(request_path)
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite) x
                    WHERE BINARY x.request_path = LOWER(core_url_rewrite.request_path)
                      AND x.store_id = core_url_rewrite.store_id);
