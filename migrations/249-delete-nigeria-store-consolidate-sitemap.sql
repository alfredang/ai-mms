-- 249: Delete the Nigeria store (website 4 / group 4 / store 4). NG shared the SG
--      install and root category 2, so only the store/website/group rows + NG-scoped
--      config are removed; the shared catalog (root cat 2) is untouched.
--      Also consolidate to a single sitemap.xml: drop the NG sitemap row and rename
--      the SG sitemap row's file from sitemap_singapore.xml to sitemap.xml.

-- NG-scoped configuration
DELETE FROM core_config_data WHERE (scope = 'stores' AND scope_id = 4) OR (scope = 'websites' AND scope_id = 4);

-- NG sitemap row (no FK cascade on sitemap.store_id)
DELETE FROM sitemap WHERE store_id = 4;

-- Break the group->default_store self-reference, then remove store/group/website
UPDATE core_store_group SET default_store_id = 0 WHERE group_id = 4;
DELETE FROM core_store WHERE store_id = 4;
DELETE FROM core_store_group WHERE group_id = 4;
DELETE FROM core_website WHERE website_id = 4;

-- Single canonical sitemap served directly at /sitemap.xml
UPDATE sitemap SET sitemap_filename = 'sitemap.xml' WHERE store_id = 1;
