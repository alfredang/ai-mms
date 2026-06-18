-- Decommission the Malaysia, Ghana, Bhutan, India, and Infotech storefronts.
--
-- Keep historical sales/customer/class records intact, but remove the active
-- Magento scope registry and store-scoped generated/catalog data so websites
-- 2, 3, 5, 6, and 7 can no longer be routed, selected, indexed, or assigned products.

DELETE FROM catalog_product_website
WHERE website_id IN (2, 3, 5, 6, 7);

DELETE FROM core_url_rewrite
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM catalogsearch_query
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM sitemap
WHERE store_id IN (2, 3, 5, 6, 7)
   OR sitemap_filename IN ('sitemap_malaysia.xml', 'sitemap_ghana.xml', 'sitemap_bhutan.xml', 'sitemap_india.xml', 'sitemap_infotech.xml');

DELETE FROM cms_block_store
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM cms_page_store
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM catalog_product_entity_varchar
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM catalog_product_entity_int
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM catalog_product_entity_text
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM catalog_product_entity_decimal
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM catalog_product_entity_datetime
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM catalog_category_entity_varchar
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM catalog_category_entity_int
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM catalog_category_entity_text
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM catalog_category_entity_decimal
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM catalog_category_entity_datetime
WHERE store_id IN (2, 3, 5, 6, 7);

DELETE FROM core_config_data
WHERE (scope = 'stores' AND scope_id IN (2, 3, 5, 6, 7))
   OR (scope = 'websites' AND scope_id IN (2, 3, 5, 6, 7))
   OR path LIKE '%/malaysia'
   OR path LIKE '%/ghana'
   OR path LIKE '%/bhutan'
   OR path LIKE '%/india'
   OR path LIKE '%/infotech'
   OR value LIKE '%tertiarycourses.com.my%'
   OR value LIKE '%tertiarycourses.com.gh%'
   OR value LIKE '%tertiarycourses.bt%'
   OR value LIKE '%tertiarycourses.in%'
   OR value LIKE '%tertiarycourses.co.in%'
   OR value LIKE '%tertiaryinfotech.edu.sg%';

DELETE FROM core_store
WHERE store_id IN (2, 3, 5, 6, 7)
   OR code IN ('malaysia', 'ghana', 'bhutan', 'india', 'infotech');

DELETE FROM core_store_group
WHERE group_id IN (2, 3, 5, 6, 7)
   OR website_id IN (2, 3, 5, 6, 7)
   OR name IN ('Malaysia', 'Ghana', 'Bhutan', 'India', 'Infotech');

DELETE FROM core_website
WHERE website_id IN (2, 3, 5, 6, 7)
   OR code IN ('malaysia', 'ghana', 'bhutan', 'india', 'infotech');
