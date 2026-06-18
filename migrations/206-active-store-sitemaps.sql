-- Keep Google Sitemap rows aligned with the active storefront set.
-- Active stores after Malaysia/Ghana/Bhutan/India/Infotech removal: SG, NG.
-- Generated sitemap XML files are runtime artifacts, not committed files.

DELETE FROM sitemap
WHERE store_id IN (2, 3, 5, 6, 7)
   OR sitemap_filename IN ('sitemap_malaysia.xml', 'sitemap_ghana.xml', 'sitemap_bhutan.xml', 'sitemap_india.xml', 'sitemap_infotech.xml', 'sitemap.xml');

INSERT INTO sitemap (sitemap_filename, sitemap_path, sitemap_time, store_id)
SELECT 'sitemap_singapore.xml', '/', NOW(), 1
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM sitemap WHERE store_id = 1 AND sitemap_filename = 'sitemap_singapore.xml'
);

INSERT INTO sitemap (sitemap_filename, sitemap_path, sitemap_time, store_id)
SELECT 'sitemap_nigeria.xml', '/', NOW(), 4
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM sitemap WHERE store_id = 4 AND sitemap_filename = 'sitemap_nigeria.xml'
);
