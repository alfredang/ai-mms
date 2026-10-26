-- Let the account-based approved-trainer pool control which trainer profiles
-- appear on a course page. NULL preserves the legacy trainerprofile HTML;
-- once any row for a course is 0/1, the storefront uses the explicit flags.

SET @has_show_on_storefront := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'mmd_product_trainer'
       AND COLUMN_NAME = 'show_on_storefront'
);
SET @sql := IF(
    @has_show_on_storefront = 0,
    'ALTER TABLE `mmd_product_trainer` ADD COLUMN `show_on_storefront` TINYINT(1) NULL DEFAULT NULL AFTER `sort_order`',
    'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Course TGS-2023036648: keep the four intended profiles and remove Jane Tan
-- from the website without removing her from the invitation pool.
UPDATE `mmd_product_trainer` pt
JOIN `catalog_product_entity` p ON p.entity_id = pt.product_id
SET pt.show_on_storefront = 0
WHERE p.sku = 'TGS-2023036648';

UPDATE `mmd_product_trainer` pt
JOIN `catalog_product_entity` p ON p.entity_id = pt.product_id
JOIN `admin_user` u ON u.user_id = pt.user_id
SET pt.show_on_storefront = 1
WHERE p.sku = 'TGS-2023036648'
  AND LOWER(u.email) IN (
      'sanjiv@prudentia-consulting.com',
      'eugene@pivot.com.sg',
      'kesstontang@gmail.com',
      'angch@tertiaryinfotech.com'
  );
