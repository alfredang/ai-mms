-- 332: Fill the one remaining AWS Data Engineer search term without a redirect.
-- "AWS Certified Data Engineer Assoicate" (typo'd, popularity 1) is the only
-- aws+data/engineer term on SG with redirect IS NULL — the other 10 variants
-- already point at the (live, HTTP 200) WSQ AWS Certified Data Engineer
-- Associate course page. Same target here.
--
-- NON-OVERWRITING: only fills redirect IS NULL/'' per the search-term redirect
-- policy. SG-guarded via the default-scope base_url so this is a no-op on the
-- MY/GH partner DBs (a .com.sg redirect there would be a forbidden cross-site
-- redirect). ASCII-only text, utf8-safe under apply.php's PDO charset.
UPDATE catalogsearch_query q
JOIN core_config_data c
  ON c.path = 'web/unsecure/base_url'
 AND c.scope = 'default'
 AND c.value LIKE '%www.tertiarycourses.com.sg%'
SET q.redirect = 'https://www.tertiarycourses.com.sg/wsq-aws-certified-data-engineer-associate-training.html'
WHERE q.query_text = 'AWS Certified Data Engineer Assoicate'
  AND (q.redirect IS NULL OR q.redirect = '');
