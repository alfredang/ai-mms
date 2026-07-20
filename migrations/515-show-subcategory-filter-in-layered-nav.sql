-- 515: Show the sub-category selection ("Category" filter) in the layered
-- nav sidebar on category pages that have subcategories.
--
-- Ultimo's infortis_ultramegamenu.xml unsets the category_filter child of
-- catalog.leftnav when ultramegamenu/sidemenu/hide_laynav_categories = 1
-- (it assumes the umm.sidemenu category tree is shown instead, but this
-- theme's local.xml removes umm.sidemenu from the sidebar). Flip it to 0 so
-- the stock Magento category filter renders; it hides itself automatically
-- on categories without subcategories.
INSERT INTO core_config_data (scope, scope_id, path, value)
VALUES ('default', 0, 'ultramegamenu/sidemenu/hide_laynav_categories', '0')
ON DUPLICATE KEY UPDATE value = '0';
