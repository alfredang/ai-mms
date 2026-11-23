-- C628: "CompTIA Security+ Exam Prep" -> "CompTIA Security Plus SY0 801 Exam Prep", and the slug
-- comptia-security-plus-exam-prep-training -> comptia-security-plus-sy0-801-exam-prep.
-- The course moves from exam SY0-701 to SY0-801 (Security+ V8).
--
-- 1. name, url_key/url_path, cover alt + gallery labels, meta_title (bare)/meta_description/meta_keyword.
-- 2. About (short_description) rewritten for SY0-801; topics (description, LSN_DATA) = the five official
--    SY0-801 domains, headings only. Domain 2 is now "Threats, Vulnerabilities, and Attacks".
--    Source: CompTIA Security+ V8 exam objectives (comptia.org/en-us/certifications/security/v8/).
-- 3. Cover re-rendered with the new title (R2).
-- 4. 301s: C628's system rows renamed in place, every old path 301s to the new bare slug, legacy RP rows
--    into an old path flattened onto it; search redirects repointed.
-- Duration 37.5 h / 5 sessions / $1,800, categories, trainers, funding block and the practice-exam link
-- are untouched.
--
-- SG-only (store guard) -> no-op on MY/GH. Idempotent.
-- Post-apply: refreshProductRewrite(628), flat + url reindex, cache flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C628' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL);

SET @new_title := 'CompTIA Security Plus SY0 801 Exam Prep';
SET @old_slug  := 'comptia-security-plus-exam-prep-training';
SET @new_slug  := 'comptia-security-plus-sy0-801-exam-prep';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title' AND backend_type = 'varchar');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description' AND backend_type = 'varchar');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword' AND backend_type = 'text');
SET @a_sdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_cover   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'course_image_url');

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

-- ---------------------------------------------- meta (title stored bare) -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, 'CompTIA Security+ SY0-801 Exam Prep Course' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'CompTIA Security+ SY0-801 exam prep course. Cover security concepts, threats and attacks, AI security risks, security architecture, operations and governance.' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'CompTIA Security+ course, Security+ training Singapore, SY0-801 exam prep, Security Plus certification, threats and attacks, AI security risks, security architecture, security operations' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------------------- About / topics -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sdesc, 0, @pid, '<p><strong>CompTIA Security Plus SY0 801 Exam Prep</strong> prepares you for the CompTIA Security+ certification (exam SY0-801, Security+ V8), the globally recognised baseline credential for cyber security professionals. Security+ validates the core skills needed to assess the security posture of an organisation, recommend and implement security solutions, and monitor and secure cloud, hybrid and on-premises environments. The course is designed for IT administrators, network and security professionals, and career switchers who want to start or advance a career in cyber security.</p><p>The course follows the five official SY0-801 exam domains. You will start with general security concepts, including the types of security controls and how change management affects security. Next you will study threats, vulnerabilities and attacks, covering threat actors and their motivations, threat vectors and attack surfaces, indicators of malicious activity and the security risks of artificial intelligence (AI), such as risks tied to AI models, prompts, privacy and data exposure. You will then cover <strong>security architecture</strong>, including architecture models, secure enterprise infrastructure, data protection, resilience and recovery.</p><p>The course continues with <strong>security operations</strong>, the largest domain of the exam, covering hardening of computing resources, asset management, vulnerability management, security monitoring and alerting, identity and access management, automation and orchestration, incident response and the use of data sources in investigations. It closes with security program management and oversight, covering governance, risk management, third-party risk, compliance and privacy, audits and assessments, and security awareness. Each domain includes practical examples, performance-based question practice and exam strategies. By the end, you will have a strong foundation in cyber security and be well prepared to pass the CompTIA Security+ SY0-801 exam.</p>' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title": "Topic 1: General Security Concepts", "subsecs": []}, {"title": "Topic 2: Threats, Vulnerabilities, and Attacks", "subsecs": []}, {"title": "Topic 3: Security Architecture", "subsecs": []}, {"title": "Topic 4: Security Operations", "subsecs": []}, {"title": "Topic 5: Security Program Management and Oversight", "subsecs": []}] -->\n<p><strong>Topic 1: General Security Concepts</strong></p>\n<p><strong>Topic 2: Threats, Vulnerabilities, and Attacks</strong></p>\n<p><strong>Topic 3: Security Architecture</strong></p>\n<p><strong>Topic 4: Security Operations</strong></p>\n<p><strong>Topic 5: Security Program Management and Oversight</strong></p>' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- store-scoped overrides would shadow the store-0 values
DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_sdesc, @a_desc, @a_mkey) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C628-20261120-102152.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------- 301 rewrites ----
-- 0) Squatters on a path C628 will occupy -> delete.
DROP TEMPORARY TABLE IF EXISTS tmp_c628_new;
CREATE TEMPORARY TABLE tmp_c628_new (store_id SMALLINT, p VARCHAR(255));
INSERT INTO tmp_c628_new
SELECT store_id, REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
  FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));
DELETE r FROM core_url_rewrite r
  JOIN tmp_c628_new n ON n.store_id = r.store_id AND n.p = r.request_path
 WHERE @ok AND r.is_system = 0 AND (r.product_id IS NULL OR r.product_id <> @pid);
DROP TEMPORARY TABLE IF EXISTS tmp_c628_new;

-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c628_old;
CREATE TEMPORARY TABLE tmp_c628_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c628_old
SELECT store_id, request_path FROM core_url_rewrite
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 2) Rename those system rows in place, so the new slug resolves immediately.
UPDATE core_url_rewrite
   SET request_path = REPLACE(request_path, CONCAT(@old_slug, '.html'), CONCAT(@new_slug, '.html'))
 WHERE @ok AND product_id = @pid AND is_system = 1
   AND (request_path = CONCAT(@old_slug, '.html') OR request_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 3) Legacy RP rows that pointed at any old-slug path -> the new bare slug (one hop).
UPDATE core_url_rewrite
   SET target_path = CONCAT(@new_slug, '.html')
 WHERE @ok AND options = 'RP'
   AND (target_path = CONCAT(@old_slug, '.html') OR target_path LIKE CONCAT('%/', @old_slug, '.html'));

-- 4) Every old path 301s to the new bare slug.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options)
SELECT o.store_id, CONCAT('manual-301-', MD5(o.request_path), '-', o.store_id), o.request_path,
       CONCAT(@new_slug, '.html'), 0, 'RP'
  FROM tmp_c628_old o;
DROP TEMPORARY TABLE IF EXISTS tmp_c628_old;

-- ------------------------------------------------- search redirects -----
UPDATE catalogsearch_query
   SET redirect = REPLACE(redirect, CONCAT('/', @old_slug, '.html'), CONCAT('/', @new_slug, '.html'))
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
