-- Give Singapore transactional emails a new, immutable logo URL.
-- Gmail proxies remote images by URL, so replacing bytes at the retired
-- Tertiary-Courses filename does not update messages that reuse that URL.
UPDATE core_config_data
SET value = 'default/Tertiary-Infotech-Academy-Email.jpg'
WHERE @mms_instance = 'SG'
  AND path = 'design/email/logo';

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'design/email/logo', 'default/Tertiary-Infotech-Academy-Email.jpg'
WHERE @mms_instance = 'SG'
  AND NOT EXISTS (
      SELECT 1
      FROM core_config_data
      WHERE scope = 'default'
        AND scope_id = 0
        AND path = 'design/email/logo'
  );

UPDATE core_config_data
SET value = 'Tertiary Infotech Academy'
WHERE @mms_instance = 'SG'
  AND path = 'design/email/logo_alt';

INSERT INTO core_config_data (scope, scope_id, path, value)
SELECT 'default', 0, 'design/email/logo_alt', 'Tertiary Infotech Academy'
WHERE @mms_instance = 'SG'
  AND NOT EXISTS (
      SELECT 1
      FROM core_config_data
      WHERE scope = 'default'
        AND scope_id = 0
        AND path = 'design/email/logo_alt'
  );
