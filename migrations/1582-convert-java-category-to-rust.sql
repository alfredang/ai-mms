-- 1582: convert the "Java" category (SG cat 75, under Programming) into "Rust".
--   name     Java                      -> Rust
--   url_key  java-programming-courses  -> rust-programming-courses
--   description + meta_title/description/keywords rewritten for Rust.
--   The banner image (java-programming-courses.png) is a generic coding photo
--   with no Java text -- kept.
--
-- Membership (requested 2026-09-28):
--   + TGS-2023039924  WSQ - AI Vibe Coding with Rust            (now the only course)
--   - TGS-2024048313  WSQ - AI Vibe Coding for Android Apps Development
--                     (already listed in Mobile Apps and both AI Vibe Coding
--                     categories -- it just leaves this one)
--   - C1809           Pearson Vue Certified IT Specialist Java (disabled; a Java
--                     course has no place on the Rust page)
--
-- The old URL is a JAVA page, so java-programming-courses.html 301s to the parent
-- programming-courses.html, not to Rust. Its 9 Java search-term redirects are
-- cleared so those searches show normal results instead of landing on Rust.
-- Old java-programming-courses/<course>.html system rows become 301s to the
-- course's flat URL (disabled course -> Programming), and every legacy 301 that
-- targeted any old path is flattened to its final destination
-- (feedback_category_slug_rename_breaks_stored_redirects_and_chains,
--  feedback_repurpose_must_flatten_category_prefixed_301_targets).
--
-- SG-guarded (store code 'singapore'): the Rust course is TGS- (SG only), so a
-- partner's Java page stays as it is. Idempotent, and safe to re-run after a
-- catalog_url reindex (old-prefix rows only; see
-- feedback_retire_category_rerun_after_reindex_collides_on_prefixed_rows).
--
-- AFTER APPLYING ON PROD: reindex catalog_category_flat, catalog_url,
-- catalog_category_product, re-run this file, flush caches.

SET @is_sg := (SELECT COUNT(*) FROM core_store WHERE code = 'singapore');

SET @a_name   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'name');
SET @a_urlkey := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_key');
SET @a_urlpth := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'url_path');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'description');
SET @a_metat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_title');
SET @a_metad  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_description');
SET @a_metak  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 3 AND attribute_code = 'meta_keywords');
SET @a_pstat  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'status');

SET @old := 'java-programming-courses';
SET @new := 'rust-programming-courses';

SET @prog := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  WHERE @is_sg > 0 AND v.attribute_id = @a_urlkey AND v.store_id = 0 AND v.value = 'programming-courses'
  LIMIT 1);

SET @cat := (SELECT v.entity_id FROM catalog_category_entity_varchar v
  JOIN catalog_category_entity e ON e.entity_id = v.entity_id AND e.parent_id = @prog
  WHERE v.attribute_id = @a_urlkey AND v.store_id = 0 AND v.value IN (@old, @new)
  LIMIT 1);

SET @rust := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023039924' LIMIT 1);

SET @dst_old := 'programming-courses.html';
SET @ok := (@cat IS NOT NULL AND @rust IS NOT NULL);

SET @new_name  := 'Rust';
SET @new_metat := 'Rust Programming Courses in Singapore';
SET @new_metad := 'Learn Rust programming in Singapore: ownership and borrowing, safe concurrency, Cargo and crates, and AI-assisted vibe coding for fast, memory-safe applications. WSQ courses with SkillsFuture funding.';
SET @new_metak := 'Rust courses, Rust programming, learn Rust, Rust training Singapore, systems programming, memory safety, Cargo, AI vibe coding, WSQ Rust course';
SET @new_desc  := '<p>Rust is a modern systems programming language that delivers the speed of C and C++ with guaranteed memory safety. Its ownership and borrowing model catches whole classes of bugs - null pointer errors, data races and use-after-free - at compile time, without a garbage collector. That combination has made Rust the most admired language in developer surveys year after year, and it now powers command-line tools, web services, WebAssembly, embedded devices, blockchain platforms and performance-critical components at companies such as Microsoft, Amazon, Google and Cloudflare.</p><p>Our Rust courses take you from the core language to building working applications: variables, types and control flow, ownership, borrowing and lifetimes, structs, enums and pattern matching, error handling with Result and Option, traits and generics, collections, modules, and safe concurrency, all managed with Cargo and the crates ecosystem. You will also learn how AI coding assistants and vibe coding workflows speed up writing, explaining, testing and refactoring Rust code, so you can be productive in a language known for its steep learning curve.</p><p>Whether you are a software developer adding a high-performance language to your toolkit or an engineer moving into systems, backend or embedded work, our hands-on, instructor-led classes help you write fast, reliable Rust with confidence. WSQ courses are eligible for SkillsFuture funding. Browse the courses below to get started.</p>';

-- ---------------------------------------------------------------------------
-- 1. EAV (store 0) - name, slug, url_path, description, meta
-- ---------------------------------------------------------------------------

UPDATE catalog_category_entity_varchar SET value = @new_name
WHERE @ok AND entity_id = @cat AND attribute_id = @a_name AND store_id = 0;

UPDATE catalog_category_entity_varchar SET value = @new
WHERE @ok AND entity_id = @cat AND attribute_id = @a_urlkey AND store_id = 0;

UPDATE catalog_category_entity_varchar SET value = REPLACE(value, CONCAT(@old, '.html'), CONCAT(@new, '.html'))
WHERE @ok AND entity_id = @cat AND attribute_id = @a_urlpth;

UPDATE catalog_category_entity_varchar SET value = @new_metat
WHERE @ok AND entity_id = @cat AND attribute_id = @a_metat AND store_id = 0;

INSERT INTO catalog_category_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, @a_metat, 0, @cat, @new_metat FROM DUAL
WHERE @ok AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_varchar x
  WHERE x.entity_id = @cat AND x.attribute_id = @a_metat AND x.store_id = 0);

UPDATE catalog_category_entity_text SET value = @new_desc
WHERE @ok AND entity_id = @cat AND attribute_id = @a_desc AND store_id = 0;

UPDATE catalog_category_entity_text SET value = @new_metad
WHERE @ok AND entity_id = @cat AND attribute_id = @a_metad AND store_id = 0;

UPDATE catalog_category_entity_text SET value = @new_metak
WHERE @ok AND entity_id = @cat AND attribute_id = @a_metak AND store_id = 0;

INSERT INTO catalog_category_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 3, a.attribute_id, 0, @cat, a.val
FROM (SELECT @a_desc AS attribute_id, @new_desc AS val
      UNION ALL SELECT @a_metad, @new_metad
      UNION ALL SELECT @a_metak, @new_metak) a
WHERE @ok AND NOT EXISTS (SELECT 1 FROM catalog_category_entity_text x
  WHERE x.entity_id = @cat AND x.attribute_id = a.attribute_id AND x.store_id = 0);

-- Store-scope overrides would shadow the new store-0 values.
DELETE FROM catalog_category_entity_varchar
WHERE @ok AND entity_id = @cat AND store_id <> 0 AND attribute_id IN (@a_name, @a_urlkey, @a_metat);
DELETE FROM catalog_category_entity_text
WHERE @ok AND entity_id = @cat AND store_id <> 0 AND attribute_id IN (@a_desc, @a_metad, @a_metak);

-- ---------------------------------------------------------------------------
-- 2. Membership: the Rust course only
-- ---------------------------------------------------------------------------

DELETE FROM catalog_category_product
WHERE @ok AND category_id = @cat AND product_id <> @rust;

DELETE FROM catalog_category_product_index
WHERE @ok AND category_id = @cat AND product_id <> @rust;

INSERT IGNORE INTO catalog_category_product (category_id, product_id, position)
SELECT @cat, @rust, 1 FROM DUAL WHERE @ok;

-- Mirror into the listing index for every store the course is already indexed in.
INSERT IGNORE INTO catalog_category_product_index (category_id, product_id, position, is_parent, store_id, visibility)
SELECT @cat, @rust, 1, 1, i.store_id, MAX(i.visibility)
  FROM catalog_category_product_index i
 WHERE @ok AND i.product_id = @rust AND i.category_id <> @cat
 GROUP BY i.store_id;

-- ---------------------------------------------------------------------------
-- 3. Flat table (the storefront reads name/meta/url from here)
-- ---------------------------------------------------------------------------

SET @has_flat := (SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'catalog_category_flat_store_1');

SET @sql := IF(@has_flat > 0 AND @ok,
  'UPDATE catalog_category_flat_store_1 SET name = @new_name, url_key = @new, url_path = CONCAT(@new, ''.html''), description = @new_desc, meta_title = @new_metat, meta_description = @new_metad, meta_keywords = @new_metak WHERE entity_id = @cat',
  'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---------------------------------------------------------------------------
-- 4. URL rewrites
-- ---------------------------------------------------------------------------

-- 4a. category system row -> new slug
UPDATE core_url_rewrite SET request_path = CONCAT(@new, '.html')
WHERE @ok AND id_path = CONCAT('category/', @cat) AND is_system = 1
  AND request_path = CONCAT(@old, '.html');

-- 4b. 301 the old Java category URL to Programming (the system row moved off it in 4a)
INSERT INTO core_url_rewrite (store_id, category_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, NULL, CONCAT('mmd_cat_rename_', MD5(CONCAT(@old, '.html'))),
       CONCAT(@old, '.html'), @dst_old, 0, 'RP'
FROM core_store s
WHERE @ok AND s.store_id > 0 AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite) x
  WHERE x.request_path = CONCAT(@old, '.html') AND x.store_id = s.store_id);

-- 4c. old java-programming-courses/<course>.html system rows -> 301 to the course's
--     flat URL (enabled) or Programming (disabled). Old prefix only, so a re-run
--     after a catalog_url reindex never touches the regenerated rust-... rows.
DROP TEMPORARY TABLE IF EXISTS tmp_java_prod;
CREATE TEMPORARY TABLE tmp_java_prod (
  url_rewrite_id INT UNSIGNED PRIMARY KEY, store_id SMALLINT UNSIGNED,
  old_path VARCHAR(255), new_target VARCHAR(255));
INSERT INTO tmp_java_prod
SELECT t.url_rewrite_id, t.store_id, t.request_path,
       IF(st.value_id IS NOT NULL AND p.request_path IS NOT NULL, p.request_path, @dst_old)
  FROM core_url_rewrite t
  LEFT JOIN core_url_rewrite p ON p.id_path = CONCAT('product/', t.product_id) AND p.store_id = t.store_id
   AND p.is_system = 1 AND p.options IS NULL
  LEFT JOIN catalog_product_entity_int st ON st.entity_id = t.product_id AND st.store_id = 0
   AND st.attribute_id = @a_pstat AND st.value = 1
 WHERE @ok AND t.category_id = @cat AND t.product_id IS NOT NULL AND t.is_system = 1
   AND t.request_path LIKE 'java-programming-courses/%';

-- legacy 301s that targeted an old prefixed course path -> its final destination
UPDATE core_url_rewrite a
  JOIN tmp_java_prod m ON m.old_path = a.target_path AND m.store_id = a.store_id
   SET a.target_path = m.new_target
 WHERE a.options IN ('R','RP') AND a.request_path <> m.new_target;

UPDATE core_url_rewrite a
  JOIN tmp_java_prod m ON m.url_rewrite_id = a.url_rewrite_id
   SET a.target_path = m.new_target, a.options = 'RP', a.is_system = 0,
       a.category_id = NULL, a.product_id = NULL,
       a.id_path = CONCAT('mmd_cat_rename_', MD5(m.old_path));

DROP TEMPORARY TABLE IF EXISTS tmp_java_prod;

-- 4d. flatten any remaining 301 whose TARGET is the old category URL or an old
--     prefixed path with no live row behind it
UPDATE core_url_rewrite
SET target_path = @dst_old
WHERE @ok AND is_system = 0 AND options IN ('R','RP')
  AND request_path <> @dst_old
  AND (target_path = CONCAT(@old, '.html')
       OR (target_path LIKE 'java-programming-courses/%'
           AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite) x
                           WHERE x.request_path = core_url_rewrite.target_path
                             AND x.store_id = core_url_rewrite.store_id)));

-- ---------------------------------------------------------------------------
-- 5. Java search-term redirects: clear, so they show search results, not Rust
-- ---------------------------------------------------------------------------

UPDATE catalogsearch_query SET redirect = ''
WHERE @ok AND redirect LIKE '%/java-programming-courses.html';
