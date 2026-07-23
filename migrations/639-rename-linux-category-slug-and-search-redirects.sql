-- 639: Category 'Linux' (SG id 76) slug: operating-systems-training-courses -> linux-courses,
--      following the course-title convention, with a 301 left behind. Then route GENERIC
--      linux search terms at the new category page.
--
-- Slug rename follows the 566/567 lesson: the naive "NOT EXISTS old request_path" INSERT
-- guard is blocked by Magento's own is_system=1 row, so instead we CONVERT that stale
-- is_system row into an is_system=0 / options='RP' 301 pointing at the new slug — the
-- exact shape Magento writes for a url_key change, and it survives the Catalog URL
-- Rewrites reindex (which recreates the new slug's is_system row).
--
-- Search redirects are SG-gated (absolute .com.sg URLs must never land on partner DBs).
-- Only GENERIC topic queries are re-routed to the category; queries naming a specific
-- live course (Linux for Beginners, CompTIA Linux+, WSQ Linux Configuration and Shell
-- Scripting, Linux Foundation exam prep, Android-with-Linux) keep their intentional
-- product redirects. A final empty-only backfill catches linux rows created later.
--
-- The slug rename itself is NOT SG-gated: catalog parity means MY/GH carry the same
-- category + slug, and the rewrite paths are relative (each site 301s on its own domain).
-- Idempotent throughout. After deploy: reindex Catalog URL Rewrites + Category Flat
-- Data and flush cache (reindex API with flush=1).

SET @a_uk := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @old := 'operating-systems-training-courses';
SET @new := 'linux-courses';
SET @cid := (SELECT uk.entity_id FROM catalog_category_entity_varchar uk
             WHERE uk.attribute_id = @a_uk AND uk.store_id = 0 AND uk.value = @old LIMIT 1);

-- 1. Convert the stale is_system rows for the old slug into proper 301s.
UPDATE core_url_rewrite
SET target_path = CONCAT(@new, '.html'), is_system = 0, options = 'RP', description = 'slug 301 (639)'
WHERE @cid IS NOT NULL AND product_id IS NULL
  AND request_path = CONCAT(@old, '.html')
  AND target_path <> CONCAT(@new, '.html');

-- 2. Re-point any existing inbound 301 chain at the new slug (no 301->301 hops).
UPDATE core_url_rewrite
SET target_path = CONCAT(@new, '.html')
WHERE @cid IS NOT NULL AND product_id IS NULL AND options = 'RP'
  AND target_path = CONCAT(@old, '.html')
  AND request_path <> CONCAT(@old, '.html');

-- 3. Rename the url_key (store 0 and any per-store override).
UPDATE catalog_category_entity_varchar SET value = @new
WHERE attribute_id = @a_uk AND value = @old;

-- 4. Mirror into whichever category-flat store tables exist.
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_1')>0,
  CONCAT("UPDATE catalog_category_flat_store_1 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_2')>0,
  CONCAT("UPDATE catalog_category_flat_store_2 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s := IF((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='catalog_category_flat_store_3')>0,
  CONCAT("UPDATE catalog_category_flat_store_3 SET url_key='", @new, "', url_path='", @new, ".html' WHERE url_key='", @old, "'"), 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- Search-term redirects (SG only): generic linux queries -> the category page.
-- ---------------------------------------------------------------------------
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @cat := 'https://www.tertiarycourses.com.sg/linux-courses.html';

UPDATE catalogsearch_query SET redirect = @cat
WHERE @sg = 1 AND query_text IN (
  'Linux', 'Linux course', 'linux courses', 'linux training', 'LINUX  training',
  'Linux command line', 'linux programming', 'linux programming course',
  'basic linux programming', 'programming for linux', 'linux script',
  'linux administrator', 'Linux Administration', 'Linux admin',
  'Linux System administration', 'linux bash programming', 'linux and bash',
  'embedded linux', 'linux unix', 'Redhat Linux', 'Linux red hat', 'red linux',
  'linux ubuntu', 'ubuntu LINUX  training', 'linux kernel', 'linux application',
  'linux introduction', 'linux security', 'linux servers', 'linux Mint',
  'Harden linux', 'linux install', 'linux essential', 'linux essential course',
  'Linux Essential Training', 'linux for essentials', 'advance linux',
  'Advanced Linux course', 'Advance Linux course', 'linux advanced',
  'Advanced level linux', 'learn the basics of linux', 'linux elastic',
  'linux and sql', 'linux and aql', 'linux mssql', 'linux cert'
);

-- Backfill: any other linux query with NO redirect yet also goes to the category.
UPDATE catalogsearch_query SET redirect = @cat
WHERE @sg = 1 AND query_text LIKE '%linux%'
  AND (redirect IS NULL OR redirect = '');
