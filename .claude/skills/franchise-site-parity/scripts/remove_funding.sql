-- Remove all SG-only funding (WSQ/IBF/SkillsFuture) from the partner. PARTNER-DB-ONLY.
-- <websiteId> = partner website scope_id; <storeId> = partner store id.

-- 1) Course-page + blog funding CTAs are hardcoded in SHARED templates -> hide GH-only via
--    website-scope head-includes CSS (append; guard for idempotency).
UPDATE core_config_data
SET value = CONCAT(value,
  '<style>.mmd-blog-cta > p{display:none !important;}.mmd-blog-sub{display:none !important;}'
  '.course-policy-card--wsq,.funding-tile,.wsq-funding{display:none !important;}</style>')
WHERE path='design/head/includes' AND scope='websites' AND scope_id=<websiteId>
  AND value NOT LIKE '%mmd-blog-cta > p%';
-- (Confirm the exact funding element classes on the partner course page; add them above.)

-- 2) Text that flows through $this->__() (e.g. the WhatsApp popup) -> per-store core_translate.
--    Match the __() string EXACTLY; the load matches by `string`; crc_string=CRC32(string).
--    CRITICAL: use the STORE's locale, not always en_US. GH=en_US, MY=en_GB. Check:
--    SELECT value FROM core_config_data WHERE path='general/locale/code' AND scope='stores' AND scope_id=<id>;
--    (An en_US row on an en_GB store does nothing.) Below uses en_US — change per store.
INSERT INTO core_translate (store_id, locale, string, translate, crc_string) VALUES
 (<storeId>,'en_US','Course Funding','Course Info', CRC32('Course Funding')),
 (<storeId>,'en_US','SFC, WSQ, IBF, SFEC, UTAP, PSEA','Course details, dates & fees', CRC32('SFC, WSQ, IBF, SFEC, UTAP, PSEA')),
 (<storeId>,'en_US','Hi %s, I would like to enquire about course funding / subsidies.','Hi %s, I would like to enquire about course information.', CRC32('Hi %s, I would like to enquire about course funding / subsidies.'))
ON DUPLICATE KEY UPDATE translate = VALUES(translate);
-- Flush cache. Verify: 0 'WSQ'/'SkillsFuture'/'Course Funding' in partner visible text.
