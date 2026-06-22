-- 213: Remove the entire "Kids & Tours" menu (category 121) and all kids products.
--
-- Tree 121 -> Educational Tours (102), Tech For Kids (215), Art and Language for Kids (158)
-- and their 20 leaf categories. Products are all K-prefixed kids courses (verified: none
-- are WSQ/adult/IBF courses). FK CASCADE cleans EAV, links, flat, url rewrites.
-- Redirect of kids/stem searches to ai4kids.tertiarycourses.com.sg is in migration 214.
--
-- NOTE: SG and Nigeria share root category 2, so this removes Kids & Tours from both.

DELETE FROM catalog_category_entity WHERE entity_id = 121 OR path LIKE '1/2/121/%';

-- Kids products (SKU K****). Double-keyed on entity_id + SKU prefix as a safety belt.
DELETE FROM catalog_product_entity WHERE entity_id IN (145,170,194,284,320,374,399,486,528,546,598,599,612,634,758,760,761,974,1021,1022,1023,1024,1026,1029,1037,1040,1094,1320,1321,1322,1323,1336,1337,1338,1339,1340,1341,1342,1343) AND sku LIKE 'K%';
