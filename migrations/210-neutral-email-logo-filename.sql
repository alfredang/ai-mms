-- Stop exposing the retired Infotech brand in the public transactional-email logo URL.
UPDATE core_config_data
SET value = 'default/Tertiary-Courses-Email.jpg'
WHERE path = 'design/email/logo'
  AND value = 'default/Infotech-Academy-Email.jpg';
