-- 273: Some country DBs (confirmed: GH, MY) were missing the mandatory
--      cataloginventory_stock seed row (stock_id=1, 'Default'). Without it,
--      the stock_status and catalogsearch_fulltext indexers join against
--      zero stock rows and silently produce zero rows for every product,
--      even though catalog_product_website / cataloginventory_stock_item
--      are fully populated. This broke category pages and search on the
--      affected stores with no error anywhere. INSERT IGNORE makes this a
--      no-op on instances that already have the row.
INSERT IGNORE INTO `cataloginventory_stock` (`stock_id`, `stock_name`) VALUES (1, 'Default');
