-- 1946: category URL slugs that stopped at a dangling "-in" (owner request 2026-11-20).
--
--   17 active SG categories carried a url_key cut off at "-in" (the old "...-in-singapore" keys, truncated),
--   e.g. android-programming-courses-in. Each loses the "-in"; Android (78) becomes
--   android-app-development-courses to match its "Android App Development Courses Singapore" title.
--   Per the course-url-change skill, for every category:
--     A. url_key                         -> new key
--     B. own url_path (every scope)      -> last segment replaced
--     C. descendants' nested url_path    -> parent segment replaced
--     D. system rewrite category/<id>    -> new request_path
--     E. redirects that targeted the old page -> target the new page (no 301 chains)
--     F. old .html -> new .html, options 'RP' (301), stores 0 and 1
--     G. stored search-term redirects    -> new URL
--     H. links in blog posts and category text -> new URL
--   Product-in-category paths under the old key are left as they are (they still resolve).
--   PROBED on SG prod 2026-11-20: no rewrite exists at any new request_path. Every statement is guarded by
--   the exact old value, so it is peer-safe, idempotent, and a no-op on MY/GH (@sg guard).
--   Post-apply: flush cache; verify old = 301 -> 200 and new = 200 for all 17.

SET NAMES utf8mb4;
SET @sg := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @cet := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_category');
SET @a_uk := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_key'  AND entity_type_id=@cet);
SET @a_up := (SELECT attribute_id FROM eav_attribute WHERE attribute_code='url_path' AND entity_type_id=@cet);

-- ---------------------------------------------------------------- category 8: digital-marketing-courses-in -> digital-marketing-courses
UPDATE catalog_category_entity_varchar SET value = 'digital-marketing-courses'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 8 AND value = 'digital-marketing-courses-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('digital-marketing-courses-in.html')), 'digital-marketing-courses.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 8 AND (value = 'digital-marketing-courses-in.html' OR value LIKE '%/digital-marketing-courses-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/digital-marketing-courses-in/', '/digital-marketing-courses/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/digital-marketing-courses-in/%';
UPDATE core_url_rewrite SET request_path = 'digital-marketing-courses.html'
 WHERE @sg = 1 AND id_path = 'category/8' AND request_path = 'digital-marketing-courses-in.html';
UPDATE core_url_rewrite SET target_path = 'digital-marketing-courses.html'
 WHERE @sg = 1 AND target_path = 'digital-marketing-courses-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('digital-marketing-courses-in.html'), '-', s.store_id), 'digital-marketing-courses-in.html', 'digital-marketing-courses.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'digital-marketing-courses-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/digital-marketing-courses-in.html', '/digital-marketing-courses.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/digital-marketing-courses-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/digital-marketing-courses-in.html', '/digital-marketing-courses.html')
 WHERE @sg = 1 AND content LIKE '%/digital-marketing-courses-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/digital-marketing-courses-in.html', '/digital-marketing-courses.html')
 WHERE @sg = 1 AND value LIKE '%/digital-marketing-courses-in.html%';

-- ---------------------------------------------------------------- category 56: iot-robotics-courses-in -> iot-robotics-courses
UPDATE catalog_category_entity_varchar SET value = 'iot-robotics-courses'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 56 AND value = 'iot-robotics-courses-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('iot-robotics-courses-in.html')), 'iot-robotics-courses.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 56 AND (value = 'iot-robotics-courses-in.html' OR value LIKE '%/iot-robotics-courses-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/iot-robotics-courses-in/', '/iot-robotics-courses/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/iot-robotics-courses-in/%';
UPDATE core_url_rewrite SET request_path = 'iot-robotics-courses.html'
 WHERE @sg = 1 AND id_path = 'category/56' AND request_path = 'iot-robotics-courses-in.html';
UPDATE core_url_rewrite SET target_path = 'iot-robotics-courses.html'
 WHERE @sg = 1 AND target_path = 'iot-robotics-courses-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('iot-robotics-courses-in.html'), '-', s.store_id), 'iot-robotics-courses-in.html', 'iot-robotics-courses.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'iot-robotics-courses-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/iot-robotics-courses-in.html', '/iot-robotics-courses.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/iot-robotics-courses-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/iot-robotics-courses-in.html', '/iot-robotics-courses.html')
 WHERE @sg = 1 AND content LIKE '%/iot-robotics-courses-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/iot-robotics-courses-in.html', '/iot-robotics-courses.html')
 WHERE @sg = 1 AND value LIKE '%/iot-robotics-courses-in.html%';

-- ---------------------------------------------------------------- category 59: email-marketing-courses-in -> email-marketing-courses
UPDATE catalog_category_entity_varchar SET value = 'email-marketing-courses'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 59 AND value = 'email-marketing-courses-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('email-marketing-courses-in.html')), 'email-marketing-courses.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 59 AND (value = 'email-marketing-courses-in.html' OR value LIKE '%/email-marketing-courses-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/email-marketing-courses-in/', '/email-marketing-courses/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/email-marketing-courses-in/%';
UPDATE core_url_rewrite SET request_path = 'email-marketing-courses.html'
 WHERE @sg = 1 AND id_path = 'category/59' AND request_path = 'email-marketing-courses-in.html';
UPDATE core_url_rewrite SET target_path = 'email-marketing-courses.html'
 WHERE @sg = 1 AND target_path = 'email-marketing-courses-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('email-marketing-courses-in.html'), '-', s.store_id), 'email-marketing-courses-in.html', 'email-marketing-courses.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'email-marketing-courses-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/email-marketing-courses-in.html', '/email-marketing-courses.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/email-marketing-courses-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/email-marketing-courses-in.html', '/email-marketing-courses.html')
 WHERE @sg = 1 AND content LIKE '%/email-marketing-courses-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/email-marketing-courses-in.html', '/email-marketing-courses.html')
 WHERE @sg = 1 AND value LIKE '%/email-marketing-courses-in.html%';

-- ---------------------------------------------------------------- category 60: blender-3d-software-training-in -> blender-3d-software-training
UPDATE catalog_category_entity_varchar SET value = 'blender-3d-software-training'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 60 AND value = 'blender-3d-software-training-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('blender-3d-software-training-in.html')), 'blender-3d-software-training.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 60 AND (value = 'blender-3d-software-training-in.html' OR value LIKE '%/blender-3d-software-training-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/blender-3d-software-training-in/', '/blender-3d-software-training/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/blender-3d-software-training-in/%';
UPDATE core_url_rewrite SET request_path = 'blender-3d-software-training.html'
 WHERE @sg = 1 AND id_path = 'category/60' AND request_path = 'blender-3d-software-training-in.html';
UPDATE core_url_rewrite SET target_path = 'blender-3d-software-training.html'
 WHERE @sg = 1 AND target_path = 'blender-3d-software-training-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('blender-3d-software-training-in.html'), '-', s.store_id), 'blender-3d-software-training-in.html', 'blender-3d-software-training.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'blender-3d-software-training-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/blender-3d-software-training-in.html', '/blender-3d-software-training.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/blender-3d-software-training-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/blender-3d-software-training-in.html', '/blender-3d-software-training.html')
 WHERE @sg = 1 AND content LIKE '%/blender-3d-software-training-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/blender-3d-software-training-in.html', '/blender-3d-software-training.html')
 WHERE @sg = 1 AND value LIKE '%/blender-3d-software-training-in.html%';

-- ---------------------------------------------------------------- category 65: adobe-software-training-in -> adobe-software-training
UPDATE catalog_category_entity_varchar SET value = 'adobe-software-training'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 65 AND value = 'adobe-software-training-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('adobe-software-training-in.html')), 'adobe-software-training.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 65 AND (value = 'adobe-software-training-in.html' OR value LIKE '%/adobe-software-training-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/adobe-software-training-in/', '/adobe-software-training/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/adobe-software-training-in/%';
UPDATE core_url_rewrite SET request_path = 'adobe-software-training.html'
 WHERE @sg = 1 AND id_path = 'category/65' AND request_path = 'adobe-software-training-in.html';
UPDATE core_url_rewrite SET target_path = 'adobe-software-training.html'
 WHERE @sg = 1 AND target_path = 'adobe-software-training-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('adobe-software-training-in.html'), '-', s.store_id), 'adobe-software-training-in.html', 'adobe-software-training.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'adobe-software-training-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/adobe-software-training-in.html', '/adobe-software-training.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/adobe-software-training-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/adobe-software-training-in.html', '/adobe-software-training.html')
 WHERE @sg = 1 AND content LIKE '%/adobe-software-training-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/adobe-software-training-in.html', '/adobe-software-training.html')
 WHERE @sg = 1 AND value LIKE '%/adobe-software-training-in.html%';

-- ---------------------------------------------------------------- category 67: google-software-training-in -> google-software-training
UPDATE catalog_category_entity_varchar SET value = 'google-software-training'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 67 AND value = 'google-software-training-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('google-software-training-in.html')), 'google-software-training.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 67 AND (value = 'google-software-training-in.html' OR value LIKE '%/google-software-training-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/google-software-training-in/', '/google-software-training/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/google-software-training-in/%';
UPDATE core_url_rewrite SET request_path = 'google-software-training.html'
 WHERE @sg = 1 AND id_path = 'category/67' AND request_path = 'google-software-training-in.html';
UPDATE core_url_rewrite SET target_path = 'google-software-training.html'
 WHERE @sg = 1 AND target_path = 'google-software-training-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('google-software-training-in.html'), '-', s.store_id), 'google-software-training-in.html', 'google-software-training.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'google-software-training-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/google-software-training-in.html', '/google-software-training.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/google-software-training-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/google-software-training-in.html', '/google-software-training.html')
 WHERE @sg = 1 AND content LIKE '%/google-software-training-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/google-software-training-in.html', '/google-software-training.html')
 WHERE @sg = 1 AND value LIKE '%/google-software-training-in.html%';

-- ---------------------------------------------------------------- category 73: arduino-courses-in -> arduino-courses
UPDATE catalog_category_entity_varchar SET value = 'arduino-courses'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 73 AND value = 'arduino-courses-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('arduino-courses-in.html')), 'arduino-courses.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 73 AND (value = 'arduino-courses-in.html' OR value LIKE '%/arduino-courses-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/arduino-courses-in/', '/arduino-courses/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/arduino-courses-in/%';
UPDATE core_url_rewrite SET request_path = 'arduino-courses.html'
 WHERE @sg = 1 AND id_path = 'category/73' AND request_path = 'arduino-courses-in.html';
UPDATE core_url_rewrite SET target_path = 'arduino-courses.html'
 WHERE @sg = 1 AND target_path = 'arduino-courses-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('arduino-courses-in.html'), '-', s.store_id), 'arduino-courses-in.html', 'arduino-courses.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'arduino-courses-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/arduino-courses-in.html', '/arduino-courses.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/arduino-courses-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/arduino-courses-in.html', '/arduino-courses.html')
 WHERE @sg = 1 AND content LIKE '%/arduino-courses-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/arduino-courses-in.html', '/arduino-courses.html')
 WHERE @sg = 1 AND value LIKE '%/arduino-courses-in.html%';

-- ---------------------------------------------------------------- category 74: raspberry-pi-courses-in -> raspberry-pi-courses
UPDATE catalog_category_entity_varchar SET value = 'raspberry-pi-courses'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 74 AND value = 'raspberry-pi-courses-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('raspberry-pi-courses-in.html')), 'raspberry-pi-courses.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 74 AND (value = 'raspberry-pi-courses-in.html' OR value LIKE '%/raspberry-pi-courses-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/raspberry-pi-courses-in/', '/raspberry-pi-courses/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/raspberry-pi-courses-in/%';
UPDATE core_url_rewrite SET request_path = 'raspberry-pi-courses.html'
 WHERE @sg = 1 AND id_path = 'category/74' AND request_path = 'raspberry-pi-courses-in.html';
UPDATE core_url_rewrite SET target_path = 'raspberry-pi-courses.html'
 WHERE @sg = 1 AND target_path = 'raspberry-pi-courses-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('raspberry-pi-courses-in.html'), '-', s.store_id), 'raspberry-pi-courses-in.html', 'raspberry-pi-courses.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'raspberry-pi-courses-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/raspberry-pi-courses-in.html', '/raspberry-pi-courses.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/raspberry-pi-courses-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/raspberry-pi-courses-in.html', '/raspberry-pi-courses.html')
 WHERE @sg = 1 AND content LIKE '%/raspberry-pi-courses-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/raspberry-pi-courses-in.html', '/raspberry-pi-courses.html')
 WHERE @sg = 1 AND value LIKE '%/raspberry-pi-courses-in.html%';

-- ---------------------------------------------------------------- category 78: android-programming-courses-in -> android-app-development-courses
UPDATE catalog_category_entity_varchar SET value = 'android-app-development-courses'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 78 AND value = 'android-programming-courses-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('android-programming-courses-in.html')), 'android-app-development-courses.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 78 AND (value = 'android-programming-courses-in.html' OR value LIKE '%/android-programming-courses-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/android-programming-courses-in/', '/android-app-development-courses/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/android-programming-courses-in/%';
UPDATE core_url_rewrite SET request_path = 'android-app-development-courses.html'
 WHERE @sg = 1 AND id_path = 'category/78' AND request_path = 'android-programming-courses-in.html';
UPDATE core_url_rewrite SET target_path = 'android-app-development-courses.html'
 WHERE @sg = 1 AND target_path = 'android-programming-courses-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('android-programming-courses-in.html'), '-', s.store_id), 'android-programming-courses-in.html', 'android-app-development-courses.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'android-programming-courses-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/android-programming-courses-in.html', '/android-app-development-courses.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/android-programming-courses-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/android-programming-courses-in.html', '/android-app-development-courses.html')
 WHERE @sg = 1 AND content LIKE '%/android-programming-courses-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/android-programming-courses-in.html', '/android-app-development-courses.html')
 WHERE @sg = 1 AND value LIKE '%/android-programming-courses-in.html%';

-- ---------------------------------------------------------------- category 80: c-cplusplus-csharp-training-in -> c-cplusplus-csharp-training
UPDATE catalog_category_entity_varchar SET value = 'c-cplusplus-csharp-training'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 80 AND value = 'c-cplusplus-csharp-training-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('c-cplusplus-csharp-training-in.html')), 'c-cplusplus-csharp-training.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 80 AND (value = 'c-cplusplus-csharp-training-in.html' OR value LIKE '%/c-cplusplus-csharp-training-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/c-cplusplus-csharp-training-in/', '/c-cplusplus-csharp-training/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/c-cplusplus-csharp-training-in/%';
UPDATE core_url_rewrite SET request_path = 'c-cplusplus-csharp-training.html'
 WHERE @sg = 1 AND id_path = 'category/80' AND request_path = 'c-cplusplus-csharp-training-in.html';
UPDATE core_url_rewrite SET target_path = 'c-cplusplus-csharp-training.html'
 WHERE @sg = 1 AND target_path = 'c-cplusplus-csharp-training-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('c-cplusplus-csharp-training-in.html'), '-', s.store_id), 'c-cplusplus-csharp-training-in.html', 'c-cplusplus-csharp-training.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'c-cplusplus-csharp-training-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/c-cplusplus-csharp-training-in.html', '/c-cplusplus-csharp-training.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/c-cplusplus-csharp-training-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/c-cplusplus-csharp-training-in.html', '/c-cplusplus-csharp-training.html')
 WHERE @sg = 1 AND content LIKE '%/c-cplusplus-csharp-training-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/c-cplusplus-csharp-training-in.html', '/c-cplusplus-csharp-training.html')
 WHERE @sg = 1 AND value LIKE '%/c-cplusplus-csharp-training-in.html%';

-- ---------------------------------------------------------------- category 89: wordpress-ecommerce-and-woocommerce-training-courses-in -> wordpress-ecommerce-and-woocommerce-training-courses
UPDATE catalog_category_entity_varchar SET value = 'wordpress-ecommerce-and-woocommerce-training-courses'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 89 AND value = 'wordpress-ecommerce-and-woocommerce-training-courses-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('wordpress-ecommerce-and-woocommerce-training-courses-in.html')), 'wordpress-ecommerce-and-woocommerce-training-courses.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 89 AND (value = 'wordpress-ecommerce-and-woocommerce-training-courses-in.html' OR value LIKE '%/wordpress-ecommerce-and-woocommerce-training-courses-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/wordpress-ecommerce-and-woocommerce-training-courses-in/', '/wordpress-ecommerce-and-woocommerce-training-courses/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/wordpress-ecommerce-and-woocommerce-training-courses-in/%';
UPDATE core_url_rewrite SET request_path = 'wordpress-ecommerce-and-woocommerce-training-courses.html'
 WHERE @sg = 1 AND id_path = 'category/89' AND request_path = 'wordpress-ecommerce-and-woocommerce-training-courses-in.html';
UPDATE core_url_rewrite SET target_path = 'wordpress-ecommerce-and-woocommerce-training-courses.html'
 WHERE @sg = 1 AND target_path = 'wordpress-ecommerce-and-woocommerce-training-courses-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('wordpress-ecommerce-and-woocommerce-training-courses-in.html'), '-', s.store_id), 'wordpress-ecommerce-and-woocommerce-training-courses-in.html', 'wordpress-ecommerce-and-woocommerce-training-courses.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'wordpress-ecommerce-and-woocommerce-training-courses-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/wordpress-ecommerce-and-woocommerce-training-courses-in.html', '/wordpress-ecommerce-and-woocommerce-training-courses.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/wordpress-ecommerce-and-woocommerce-training-courses-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/wordpress-ecommerce-and-woocommerce-training-courses-in.html', '/wordpress-ecommerce-and-woocommerce-training-courses.html')
 WHERE @sg = 1 AND content LIKE '%/wordpress-ecommerce-and-woocommerce-training-courses-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/wordpress-ecommerce-and-woocommerce-training-courses-in.html', '/wordpress-ecommerce-and-woocommerce-training-courses.html')
 WHERE @sg = 1 AND value LIKE '%/wordpress-ecommerce-and-woocommerce-training-courses-in.html%';

-- ---------------------------------------------------------------- category 96: javascript-training-courses-in -> javascript-training-courses
UPDATE catalog_category_entity_varchar SET value = 'javascript-training-courses'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 96 AND value = 'javascript-training-courses-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('javascript-training-courses-in.html')), 'javascript-training-courses.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 96 AND (value = 'javascript-training-courses-in.html' OR value LIKE '%/javascript-training-courses-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/javascript-training-courses-in/', '/javascript-training-courses/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/javascript-training-courses-in/%';
UPDATE core_url_rewrite SET request_path = 'javascript-training-courses.html'
 WHERE @sg = 1 AND id_path = 'category/96' AND request_path = 'javascript-training-courses-in.html';
UPDATE core_url_rewrite SET target_path = 'javascript-training-courses.html'
 WHERE @sg = 1 AND target_path = 'javascript-training-courses-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('javascript-training-courses-in.html'), '-', s.store_id), 'javascript-training-courses-in.html', 'javascript-training-courses.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'javascript-training-courses-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/javascript-training-courses-in.html', '/javascript-training-courses.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/javascript-training-courses-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/javascript-training-courses-in.html', '/javascript-training-courses.html')
 WHERE @sg = 1 AND content LIKE '%/javascript-training-courses-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/javascript-training-courses-in.html', '/javascript-training-courses.html')
 WHERE @sg = 1 AND value LIKE '%/javascript-training-courses-in.html%';

-- ---------------------------------------------------------------- category 100: gaming-animation-and-video-courses-in -> gaming-animation-and-video-courses
UPDATE catalog_category_entity_varchar SET value = 'gaming-animation-and-video-courses'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 100 AND value = 'gaming-animation-and-video-courses-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('gaming-animation-and-video-courses-in.html')), 'gaming-animation-and-video-courses.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 100 AND (value = 'gaming-animation-and-video-courses-in.html' OR value LIKE '%/gaming-animation-and-video-courses-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/gaming-animation-and-video-courses-in/', '/gaming-animation-and-video-courses/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/gaming-animation-and-video-courses-in/%';
UPDATE core_url_rewrite SET request_path = 'gaming-animation-and-video-courses.html'
 WHERE @sg = 1 AND id_path = 'category/100' AND request_path = 'gaming-animation-and-video-courses-in.html';
UPDATE core_url_rewrite SET target_path = 'gaming-animation-and-video-courses.html'
 WHERE @sg = 1 AND target_path = 'gaming-animation-and-video-courses-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('gaming-animation-and-video-courses-in.html'), '-', s.store_id), 'gaming-animation-and-video-courses-in.html', 'gaming-animation-and-video-courses.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'gaming-animation-and-video-courses-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/gaming-animation-and-video-courses-in.html', '/gaming-animation-and-video-courses.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/gaming-animation-and-video-courses-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/gaming-animation-and-video-courses-in.html', '/gaming-animation-and-video-courses.html')
 WHERE @sg = 1 AND content LIKE '%/gaming-animation-and-video-courses-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/gaming-animation-and-video-courses-in.html', '/gaming-animation-and-video-courses.html')
 WHERE @sg = 1 AND value LIKE '%/gaming-animation-and-video-courses-in.html%';

-- ---------------------------------------------------------------- category 106: r-programming-courses-in -> r-programming-courses
UPDATE catalog_category_entity_varchar SET value = 'r-programming-courses'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 106 AND value = 'r-programming-courses-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('r-programming-courses-in.html')), 'r-programming-courses.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 106 AND (value = 'r-programming-courses-in.html' OR value LIKE '%/r-programming-courses-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/r-programming-courses-in/', '/r-programming-courses/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/r-programming-courses-in/%';
UPDATE core_url_rewrite SET request_path = 'r-programming-courses.html'
 WHERE @sg = 1 AND id_path = 'category/106' AND request_path = 'r-programming-courses-in.html';
UPDATE core_url_rewrite SET target_path = 'r-programming-courses.html'
 WHERE @sg = 1 AND target_path = 'r-programming-courses-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('r-programming-courses-in.html'), '-', s.store_id), 'r-programming-courses-in.html', 'r-programming-courses.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'r-programming-courses-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/r-programming-courses-in.html', '/r-programming-courses.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/r-programming-courses-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/r-programming-courses-in.html', '/r-programming-courses.html')
 WHERE @sg = 1 AND content LIKE '%/r-programming-courses-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/r-programming-courses-in.html', '/r-programming-courses.html')
 WHERE @sg = 1 AND value LIKE '%/r-programming-courses-in.html%';

-- ---------------------------------------------------------------- category 125: project-management-training-courses-in -> project-management-training-courses
UPDATE catalog_category_entity_varchar SET value = 'project-management-training-courses'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 125 AND value = 'project-management-training-courses-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('project-management-training-courses-in.html')), 'project-management-training-courses.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 125 AND (value = 'project-management-training-courses-in.html' OR value LIKE '%/project-management-training-courses-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/project-management-training-courses-in/', '/project-management-training-courses/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/project-management-training-courses-in/%';
UPDATE core_url_rewrite SET request_path = 'project-management-training-courses.html'
 WHERE @sg = 1 AND id_path = 'category/125' AND request_path = 'project-management-training-courses-in.html';
UPDATE core_url_rewrite SET target_path = 'project-management-training-courses.html'
 WHERE @sg = 1 AND target_path = 'project-management-training-courses-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('project-management-training-courses-in.html'), '-', s.store_id), 'project-management-training-courses-in.html', 'project-management-training-courses.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'project-management-training-courses-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/project-management-training-courses-in.html', '/project-management-training-courses.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/project-management-training-courses-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/project-management-training-courses-in.html', '/project-management-training-courses.html')
 WHERE @sg = 1 AND content LIKE '%/project-management-training-courses-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/project-management-training-courses-in.html', '/project-management-training-courses.html')
 WHERE @sg = 1 AND value LIKE '%/project-management-training-courses-in.html%';

-- ---------------------------------------------------------------- category 143: internet-of-things-iot-training-in -> internet-of-things-iot-training
UPDATE catalog_category_entity_varchar SET value = 'internet-of-things-iot-training'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 143 AND value = 'internet-of-things-iot-training-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('internet-of-things-iot-training-in.html')), 'internet-of-things-iot-training.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 143 AND (value = 'internet-of-things-iot-training-in.html' OR value LIKE '%/internet-of-things-iot-training-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/internet-of-things-iot-training-in/', '/internet-of-things-iot-training/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/internet-of-things-iot-training-in/%';
UPDATE core_url_rewrite SET request_path = 'internet-of-things-iot-training.html'
 WHERE @sg = 1 AND id_path = 'category/143' AND request_path = 'internet-of-things-iot-training-in.html';
UPDATE core_url_rewrite SET target_path = 'internet-of-things-iot-training.html'
 WHERE @sg = 1 AND target_path = 'internet-of-things-iot-training-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('internet-of-things-iot-training-in.html'), '-', s.store_id), 'internet-of-things-iot-training-in.html', 'internet-of-things-iot-training.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'internet-of-things-iot-training-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/internet-of-things-iot-training-in.html', '/internet-of-things-iot-training.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/internet-of-things-iot-training-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/internet-of-things-iot-training-in.html', '/internet-of-things-iot-training.html')
 WHERE @sg = 1 AND content LIKE '%/internet-of-things-iot-training-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/internet-of-things-iot-training-in.html', '/internet-of-things-iot-training.html')
 WHERE @sg = 1 AND value LIKE '%/internet-of-things-iot-training-in.html%';

-- ---------------------------------------------------------------- category 151: networks-training-in -> networks-training
UPDATE catalog_category_entity_varchar SET value = 'networks-training'
 WHERE @sg = 1 AND attribute_id = @a_uk AND entity_id = 151 AND value = 'networks-training-in';
UPDATE catalog_category_entity_varchar SET value = CONCAT(LEFT(value, CHAR_LENGTH(value) - CHAR_LENGTH('networks-training-in.html')), 'networks-training.html')
 WHERE @sg = 1 AND attribute_id = @a_up AND entity_id = 151 AND (value = 'networks-training-in.html' OR value LIKE '%/networks-training-in.html');
UPDATE catalog_category_entity_varchar SET value = REPLACE(value, '/networks-training-in/', '/networks-training/')
 WHERE @sg = 1 AND attribute_id = @a_up AND value LIKE '%/networks-training-in/%';
UPDATE core_url_rewrite SET request_path = 'networks-training.html'
 WHERE @sg = 1 AND id_path = 'category/151' AND request_path = 'networks-training-in.html';
UPDATE core_url_rewrite SET target_path = 'networks-training.html'
 WHERE @sg = 1 AND target_path = 'networks-training-in.html';
INSERT INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT s.store_id, CONCAT('manual-301-', MD5('networks-training-in.html'), '-', s.store_id), 'networks-training-in.html', 'networks-training.html', 0, 'RP'
  FROM (SELECT 0 AS store_id UNION ALL SELECT 1) s
 WHERE @sg = 1
   AND NOT EXISTS (SELECT 1 FROM (SELECT request_path, store_id FROM core_url_rewrite WHERE request_path = 'networks-training-in.html') x WHERE x.store_id = s.store_id);
UPDATE catalogsearch_query SET redirect = REPLACE(redirect, '/networks-training-in.html', '/networks-training.html')
 WHERE @sg = 1 AND redirect LIKE '%tertiarycourses.com.sg/networks-training-in.html%';
UPDATE mmd_blog_post SET content = REPLACE(content, '/networks-training-in.html', '/networks-training.html')
 WHERE @sg = 1 AND content LIKE '%/networks-training-in.html%';
UPDATE catalog_category_entity_text SET value = REPLACE(value, '/networks-training-in.html', '/networks-training.html')
 WHERE @sg = 1 AND value LIKE '%/networks-training-in.html%';
