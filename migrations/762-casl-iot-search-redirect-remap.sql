-- 762: Remap catalogsearch_query.redirect rows still pointing at the old
-- WSQ IoT course URL to the new CASL registration URL (see 757), avoiding a
-- 301 chain on search-term redirects. Already applied live on SG prod
-- (15 rows); this file keeps the change reproducible. Partner-safe: the
-- SG-slug LIKE simply matches nothing on MY/GH.

UPDATE catalogsearch_query
  SET redirect = REPLACE(redirect, 'wsq-business-innovation-with-internet-of-things-iot', 'casl-business-innovation-with-internet-of-things-iot')
  WHERE redirect LIKE '%wsq-business-innovation-with-internet-of-things-iot%';
