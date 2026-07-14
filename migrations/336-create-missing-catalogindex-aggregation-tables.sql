-- 336: create missing catalogindex_aggregation* tables.
--
-- WHY: these are stock OpenMage/Magento core tables (Mage_CatalogIndex module,
-- added upstream in mysql4-upgrade-0.7.9-0.7.10.php) that back the "Layered
-- Navigation Cache" — specifically Mage_CatalogIndex_Model_Aggregation, used by
-- Mage_Catalog_Model_Layer_Filter_Category::_getItemsData() to cache the
-- per-category product counts shown in the storefront sidebar's "Category"
-- filter. Ghana's DB is missing all three tables entirely (confirmed via
-- direct query: `Table 'mms_gh.catalogindex_aggregation' doesn't exist`).
--
-- Effect of the gap: Mage_Catalog_Model_Category::getChildrenCategories() +
-- addCountToCategories() compute the correct counts fine (verified directly),
-- but Mage_CatalogIndex_Model_Resource_Aggregation::getCacheData()/
-- saveCacheData() silently fail against the missing table. Magento's own
-- per-block exception handling swallows that failure, so the whole page still
-- renders fine — it just silently drops the "Category" filter from the
-- sidebar with zero visible error. This is why the AI Courses landing page
-- (and any other anchor-category page) never shows a "Category" facet on
-- Ghana, while Singapore (which has these tables) does.
--
-- Idempotent: CREATE TABLE IF NOT EXISTS, so this no-ops on any site that
-- already has them (expected: Singapore). Schema copied verbatim from the
-- core module's own install script so it matches what a correctly-migrated
-- OpenMage install would already have.

CREATE TABLE IF NOT EXISTS `catalogindex_aggregation` (
    `aggregation_id` int(10) unsigned NOT NULL auto_increment,
    `store_id` smallint(5) unsigned NOT NULL,
    `created_at` datetime NOT NULL,
    `key` varchar(255) default NULL,
    `data` mediumtext,
    PRIMARY KEY  (`aggregation_id`),
    UNIQUE KEY `IDX_STORE_KEY` (`store_id`,`key`),
    CONSTRAINT `FK_CATALOGINDEX_AGGREGATION_STORE` FOREIGN KEY (`store_id`)
        REFERENCES `core_store` (`store_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `catalogindex_aggregation_tag` (
    `tag_id` int(10) unsigned NOT NULL auto_increment,
    `tag_code` varchar(255) NOT NULL,
    PRIMARY KEY  (`tag_id`),
    UNIQUE KEY `IDX_CODE` (`tag_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `catalogindex_aggregation_to_tag` (
    `aggregation_id` int(10) unsigned NOT NULL,
    `tag_id` int(10) unsigned NOT NULL,
    UNIQUE KEY `IDX_AGGREGATION_TAG` (`aggregation_id`,`tag_id`),
    KEY `FK_CATALOGINDEX_AGGREGATION_TO_TAG_TAG` (`tag_id`),
    CONSTRAINT `FK_CATALOGINDEX_AGGREGATION_TO_TAG_AGGREGATION` FOREIGN KEY (`aggregation_id`)
        REFERENCES `catalogindex_aggregation` (`aggregation_id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `FK_CATALOGINDEX_AGGREGATION_TO_TAG_TAG` FOREIGN KEY (`tag_id`)
        REFERENCES `catalogindex_aggregation_tag` (`tag_id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
