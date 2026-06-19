-- Keep Google Sitemap rows aligned with whichever stores are actually
-- active in this database. Shared across SG (multi-store, most country
-- stores already deleted by 205) and standalone country instances (each
-- owns a full store/website topology where most of it is inactive
-- elsewhere but live for that one instance).
--
-- `sitemap` was never created on some country DBs (the table only exists
-- via Magento's own Mage_Sitemap setup script, which apparently never ran
-- there), so this migration creates it defensively before touching rows.

CREATE TABLE IF NOT EXISTS `sitemap` (
  `sitemap_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sitemap_type` varchar(32) NOT NULL DEFAULT '',
  `sitemap_filename` varchar(32) NOT NULL DEFAULT '',
  `sitemap_path` varchar(255) NOT NULL DEFAULT '',
  `sitemap_time` timestamp NULL DEFAULT NULL,
  `store_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`sitemap_id`),
  KEY `IDX_SITEMAP_STORE_ID` (`store_id`),
  CONSTRAINT `FK_SITEMAP_STORE_ID` FOREIGN KEY (`store_id`) REFERENCES `core_store` (`store_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Google Sitemap';

-- Drop sitemap rows for stores that no longer exist or are inactive.
DELETE s FROM sitemap s
LEFT JOIN core_store cs ON cs.store_id = s.store_id AND cs.is_active = 1
WHERE cs.store_id IS NULL;

-- Ensure every active, non-admin store has exactly one sitemap row.
INSERT INTO sitemap (sitemap_filename, sitemap_path, sitemap_time, store_id)
SELECT CONCAT('sitemap_', cs.code, '.xml'), '/', NOW(), cs.store_id
FROM core_store cs
WHERE cs.is_active = 1 AND cs.store_id <> 0
  AND NOT EXISTS (SELECT 1 FROM sitemap WHERE store_id = cs.store_id);
