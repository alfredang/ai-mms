-- 1850: SG favicon = the Tertiary Infotech Academy icon (white "T" on a navy
--   circle, byte-identical to www.tertiaryinfotech.com/icon-192.png), so the
--   SG storefront + admin tabs match the TIA website. New filename busts cached
--   favicons. Admin templates read this same config value, so partners (MY/GH)
--   keep default/favicon_1.png. SG-only, idempotent.

UPDATE `core_config_data`
   SET `value` = 'default/favicon_tia.png'
 WHERE @mms_instance = 'SG'
   AND `path` = 'design/head/shortcut_icon';
