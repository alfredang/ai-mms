-- Native apps (TC LMS SG / MY / GH): a profile picture per account.
-- The picture is stored (re-encoded to a 512px JPEG by the API) in
-- mmd_mobile_profile and served only to the signed-in owner at
-- /mobileapi/profile/avatar. Runs identically on every site.

SET @c = (SELECT COUNT(*) FROM information_schema.COLUMNS
          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mmd_mobile_profile' AND COLUMN_NAME = 'avatar');
SET @sql = IF(@c = 0,
    'ALTER TABLE `mmd_mobile_profile` ADD COLUMN `avatar` MEDIUMBLOB NULL AFTER `phone`, ADD COLUMN `avatar_at` DATETIME NULL AFTER `avatar`',
    'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
