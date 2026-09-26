-- 1563: stop the collision-suffix climb on retired categories for good.
--
-- WHY: five retired (is_active=0) categories -- 98 ERP & CRM, 126 Marketing
-- Analytics, 183 AWS, 227 + 404 AWS Certification Exam Prep -- still have their
-- ORIGINAL url_key, but the clean /<url_key>.html slot is intentionally held by
-- the `mmd_retire/<id>` 301 to the successor category. On every container boot
-- the flat-URL job therefore sees the base "taken" and bumps the retired
-- category's canonical to the next free numeric suffix (-104 -> -105 -> -106 ->
-- -107 ...), leaving a save-history 301 behind each time. Result: a 301 ladder
-- that grows one rung per deploy and always ends on a disabled category (404).
-- 1561 flattened the ladders and 1562 re-pointed them at the successor, but
-- without this change the next boot starts a new rung.
--
-- FIX (same approach as migration 190 for the CompTIA collision): give each
-- retired category a url_key that cannot collide -- `<url_key>-retired` -- and
-- rename its canonical rewrite + url_path in place. Nothing links to the
-- retired canonical (1562 moved every inbound 301 to the successor), and a
-- disabled category's canonical 404s by design. The entrypoint's numeric-suffix
-- fixer ignores a non-numeric suffix, so the path is now stable.
--
-- Set is derived, never hardcoded: is_active=0 at store 0 AND an mmd_retire/<id>
-- row exists in store 1 AND url_key not already suffixed. Silent no-op on a
-- partner DB without mmd_retire rows. Idempotent. Applied live on SG prod first.

-- 0. Resolve the set once (temp table avoids ERROR 1093 on self-referencing updates).
DROP TEMPORARY TABLE IF EXISTS tmp_retired_cats;
CREATE TEMPORARY TABLE tmp_retired_cats (entity_id INT UNSIGNED PRIMARY KEY, old_key VARCHAR(255), new_key VARCHAR(255));
INSERT INTO tmp_retired_cats (entity_id, old_key, new_key)
SELECT k.entity_id, k.value, CONCAT(k.value, '-retired')
  FROM catalog_category_entity_varchar k
  JOIN catalog_category_entity_int ia ON ia.entity_id = k.entity_id AND ia.store_id = 0 AND ia.value = 0
   AND ia.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'is_active' AND entity_type_id = 3)
 WHERE k.store_id = 0
   AND k.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_key' AND entity_type_id = 3)
   AND k.value NOT LIKE '%-retired'
   AND EXISTS (SELECT 1 FROM core_url_rewrite r WHERE r.id_path = CONCAT('mmd_retire/', k.entity_id) AND r.store_id = 1 AND r.options IN ('R','RP'))
   AND NOT EXISTS (SELECT 1 FROM core_url_rewrite x WHERE x.request_path = CONCAT(k.value, '-retired.html'));

-- 1. url_key (default scope) + drop store-level url_key overrides.
UPDATE catalog_category_entity_varchar v
  JOIN tmp_retired_cats c ON c.entity_id = v.entity_id
   SET v.value = c.new_key
 WHERE v.store_id = 0
   AND v.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_key' AND entity_type_id = 3);

DELETE v FROM catalog_category_entity_varchar v
  JOIN tmp_retired_cats c ON c.entity_id = v.entity_id
 WHERE v.store_id <> 0
   AND v.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_key' AND entity_type_id = 3);

-- 2. url_path (default scope) so getUrl() renders the stable path immediately.
UPDATE catalog_category_entity_varchar v
  JOIN tmp_retired_cats c ON c.entity_id = v.entity_id
   SET v.value = CONCAT(c.new_key, '.html')
 WHERE v.store_id = 0
   AND v.attribute_id = (SELECT attribute_id FROM eav_attribute WHERE attribute_code = 'url_path' AND entity_type_id = 3);

-- 3. Rename the canonical rewrite in place (no save-history rung).
UPDATE core_url_rewrite r
  JOIN tmp_retired_cats c ON c.entity_id = r.category_id
   SET r.request_path = CONCAT(c.new_key, '.html')
 WHERE r.is_system = 1 AND r.product_id IS NULL AND r.options IS NULL
   AND r.request_path <> CONCAT(c.new_key, '.html');

DROP TEMPORARY TABLE IF EXISTS tmp_retired_cats;
