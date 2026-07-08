-- 333: Blender search terms — fill the one NULL redirect and rescue 4 dead-ends.
-- "blenders" (0 results, redirect NULL) plus 4 terms whose curated targets now
-- 404 on SG (3d-printing-workshop-for-kids.html, escape-room-for-kids-the-
-- environmental-rescue.html — both retired kids workshops). All 5 remap to the
-- live (HTTP 200) WSQ 3D Modelling with Blender for Beginners course page.
-- The ~45 other Blender terms keep their existing live redirects (Blender
-- category page / Blender Essential Training) — intentional, not overwritten.
--
-- Overwrite is scoped to redirect IS NULL/'' OR redirect = the exact dead URL,
-- so live product-page redirects can never be clobbered and re-runs are no-ops.
-- SG-guarded via the default-scope base_url so this is a no-op on the MY/GH
-- partner DBs (a .com.sg redirect there would be a forbidden cross-site
-- redirect). ASCII-only text, utf8-safe under apply.php's PDO charset.
UPDATE catalogsearch_query q
JOIN core_config_data c
  ON c.path = 'web/unsecure/base_url'
 AND c.scope = 'default'
 AND c.value LIKE '%www.tertiarycourses.com.sg%'
SET q.redirect = 'https://www.tertiarycourses.com.sg/wsq-3d-modelling-with-blender-for-beginners.html'
WHERE q.query_text IN (
        'blenders',
        'Blender 3D Design Workshop for Kids',
        'blender 3d printing',
        'blender kids',
        'blender kitds'
      )
  AND (q.redirect IS NULL OR q.redirect = ''
       OR q.redirect = 'https://www.tertiarycourses.com.sg/3d-printing-workshop-for-kids.html'
       OR q.redirect = 'https://www.tertiarycourses.com.sg/escape-room-for-kids-the-environmental-rescue.html');
