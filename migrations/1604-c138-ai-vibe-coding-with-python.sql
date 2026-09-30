-- C138: rename "AI Vibe Coding for Python" -> "AI Vibe Coding with Python", the
-- non-WSQ twin of TGS-2019504591 (WSQ - AI Vibe Coding with Python).
--
-- 1. name, url_key/url_path (ai-vibe-coding-for-python -> ai-vibe-coding-with-python),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 2. "What's This Course About" (short_description) and course topics (description,
--    LSN_DATA) follow the WSQ parent's 5-topic course; the old C138 copy listed a
--    different 4-topic outline and stated "2-day course".
-- 3. Funding block repointed from "WSQ - Python Fundamental Course for Beginners" to
--    the WSQ twin /wsq-ai-vibe-coding-with-python.html.
-- 4. 301s: the new slug was itself an RP row pointing at the old slug (earlier rename
--    the other way round); those rows are deleted first so nothing loops, then every
--    old path 301s one hop to the new slug.
--
-- SG-only (store guard + joins on the TGS- parent) -> no-op on MY/GH. Idempotent.
--
-- Post-deploy (not doable in SQL): refreshProductRewrite(138) + flat reindex + flush,
-- re-render the R2 cover (title is baked into the PNG), switch the schedule template
-- B19 (gid 108) -> B17 (gid 189) to match the parent's (SG) WSQ-B17.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C138' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2019504591' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @old_title := 'AI Vibe Coding for Python';
SET @new_title := 'AI Vibe Coding with Python';
SET @old_slug  := 'ai-vibe-coding-for-python';
SET @new_slug  := 'ai-vibe-coding-with-python';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

-- ------------------------------------------------------- name / slug -----
UPDATE catalog_product_entity_varchar SET value = @new_title
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_name;

UPDATE catalog_product_entity_varchar SET value = @new_slug
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlkey;

UPDATE catalog_product_entity_varchar SET value = CONCAT(@new_slug, '.html')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_urlpath;

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @new_title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @new_title
 WHERE @ok AND g.entity_id = @pid;

-- --------------------------------------------------------- meta data -----
UPDATE catalog_product_entity_varchar
   SET value = 'AI Vibe Coding with Python | Tertiary Courses Singapore'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mtitle;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Build and deploy Python apps with AI vibe coding. Master functional and OOP Python, Streamlit deployment, database integration and error handling in this hands-on course at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

UPDATE catalog_product_entity_text
   SET value = 'AI Vibe Coding, Python, vibe coding, Streamlit deployment, Python OOP, database integration Python, error handling Python, AI-assisted coding, build Python applications, Python programming Singapore'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mkey AND store_id = 0;

-- ----------------------------------------- About + topics from parent -----
UPDATE catalog_product_entity_text
   SET value = '<p>In today''s fast-paced digital environment, the ability to rapidly build and deploy applications is a key skill for developers and professionals alike. This course, AI Vibe Coding with Python, equips learners with practical skills to develop Python-based solutions using a modern, prompt-driven development approach.</p><p>Designed for learners with foundational Python knowledge, the course focuses on applying intermediate concepts such as data structures, algorithms, and the use of Python libraries within real-world application scenarios. Through Vibe Coding workflows, learners will leverage AI-assisted development techniques to accelerate coding, improve productivity, and streamline the application development lifecycle.</p><p>Participants will engage in hands-on projects to design, build, and deploy Python applications across different domains, including automation, web applications, and data-driven solutions. The course emphasizes the end-to-end development process, from ideation and implementation to testing, version control, deployment, and basic CI/CD practices.</p><p>By the end of the course, learners will be able to develop scalable Python applications, apply AI-assisted coding techniques effectively, and deploy solutions in a structured and efficient manner. This enables learners to tackle more complex development challenges and contribute to real-world projects with confidence.</p><p>This course is suitable for aspiring developers, IT professionals, and individuals looking to enhance their capabilities in Python programming, application development, and AI-assisted (Vibe Coding) workflows.</p>'
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_short AND store_id = 0;

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity_text pt
    ON pt.entity_id = @src AND pt.attribute_id = t.attribute_id AND pt.store_id = 0
   SET t.value = pt.value
 WHERE @ok AND t.entity_id = @pid AND t.attribute_id = @a_desc AND t.store_id = 0
   AND LENGTH(pt.value) = CHAR_LENGTH(pt.value);

-- ------------------------------------------------------ funding block -----
UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\n<p>No funding is available for this course</p>\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-with-python.html" title="WSQ - AI Vibe Coding with Python">WSQ - AI Vibe Coding with Python</a></span></p>'
 WHERE @ok AND identifier = 'course_C138_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Drop RP rows that would become self-loops once retargeted
--    (<prefix>/ai-vibe-coding-with-python.html -> <prefix>/ai-vibe-coding-for-python.html).
DELETE FROM core_url_rewrite
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'))
   AND request_path = REPLACE(target_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'));

-- 2) Repoint remaining RP rows targeting an old-slug path (one hop, keep prefix).
UPDATE core_url_rewrite
   SET target_path = REPLACE(target_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 3) Capture + delete the product's old system rows, re-add each as a 301.
DROP TEMPORARY TABLE IF EXISTS tmp_c138_old;
CREATE TEMPORARY TABLE tmp_c138_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c138_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

DELETE FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       REPLACE(o.request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html')), 0, 'RP'
  FROM tmp_c138_old o;

-- 4) Bare old slug -> new slug, in case no system row existed.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT 1, CONCAT('manual-301-', MD5(CONCAT(@old_slug, '.html')), '-1'),
       CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM DUAL
 WHERE @ok
   AND NOT EXISTS (SELECT 1 FROM (SELECT * FROM core_url_rewrite) x
                    WHERE x.request_path = CONCAT(@old_slug, '.html') AND x.store_id = 1);

DROP TEMPORARY TABLE IF EXISTS tmp_c138_old;

-- ------------------------------------------------- search redirects ------
UPDATE catalogsearch_query
   SET redirect = REPLACE(redirect, CONCAT('/', @old_slug, '.html'), CONCAT('/', @new_slug, '.html'))
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
