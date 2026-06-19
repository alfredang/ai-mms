-- Create OpenMage permission tables and whitelist block types used in CMS pages.
-- Tables `permission_block` and `permission_variable` were never created on
-- country DBs (MY, GH, NG, BT, IN). Without them, isTypeAllowed() returns false
-- for all block types, making every {{block type="..."}} directive in CMS pages
-- silently return empty string. (Table names come from Mage/Admin/etc/config.xml
-- entity mapping — NOT admin_block/admin_permission_variable as the upgrade
-- script DDL label suggests.)
-- Also set core_resource admin_setup to 1.6.1.5 so Magento's own upgrade scripts
-- (which lack IF NOT EXISTS) don't conflict with this migration.

CREATE TABLE IF NOT EXISTS `permission_variable` (
  `variable_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `variable_name` varchar(255) NOT NULL DEFAULT '',
  `is_allowed` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`variable_id`),
  UNIQUE KEY `UNQ_PERMISSION_VARIABLE_NAME` (`variable_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='System variables that can be processed via content filter';

INSERT IGNORE INTO `permission_variable` (`variable_name`, `is_allowed`) VALUES
('trans_email/ident_support/name',  1),
('trans_email/ident_support/email', 1),
('web/unsecure/base_url',           1),
('web/secure/base_url',             1),
('trans_email/ident_general/name',  1),
('trans_email/ident_general/email', 1),
('trans_email/ident_sales/name',    1),
('trans_email/ident_sales/email',   1),
('trans_email/ident_custom1/name',  1),
('trans_email/ident_custom1/email', 1),
('trans_email/ident_custom2/name',  1),
('trans_email/ident_custom2/email', 1),
('general/store_information/name',  1),
('general/store_information/phone', 1),
('general/store_information/address', 1);

CREATE TABLE IF NOT EXISTS `permission_block` (
  `block_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `block_name` varchar(255) NOT NULL DEFAULT '',
  `is_allowed` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`block_id`),
  UNIQUE KEY `UNQ_PERMISSION_BLOCK_NAME` (`block_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='System blocks that can be processed via content filter';

INSERT IGNORE INTO `permission_block` (`block_name`, `is_allowed`) VALUES
('core/template',                   1),
('catalog/product_new',             1),
('ultimo/product_list_featured',    1);

-- Prevent Magento upgrade scripts (upgrade-1.6.1.1-1.6.1.2.php etc.) from
-- running and conflicting with the tables we just created.
INSERT INTO `core_resource` (`code`, `version`, `data_version`)
VALUES ('admin_setup', '1.6.1.5', '1.6.1.5')
ON DUPLICATE KEY UPDATE `version` = GREATEST(`version`, '1.6.1.5'),
                         `data_version` = GREATEST(`data_version`, '1.6.1.5');
