-- 1852: MY + GH favicon = the Tertiary Infotech Academy icon, same as SG (1850)
--   and www.tertiaryinfotech.com. favicon_tia.png is seeded into
--   media/favicon/default/ by docker/entrypoint.sh (the baked copy is shadowed
--   by the media volume on partner boxes). Storefront + admin templates read
--   this config value. MY/GH-only, idempotent.

INSERT INTO `core_config_data` (`scope`, `scope_id`, `path`, `value`)
SELECT 'default', 0, 'design/head/shortcut_icon', 'default/favicon_tia.png'
  FROM DUAL
 WHERE @mms_instance IN ('MY', 'GH')
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);

UPDATE `core_config_data`
   SET `value` = 'default/favicon_tia.png'
 WHERE @mms_instance IN ('MY', 'GH')
   AND `path` = 'design/head/shortcut_icon';
