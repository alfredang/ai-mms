-- C506: "Basic Cyber Security Course" -> "Cyber Security Awareness Workshop", the 1-day
-- non-WSQ twin of TGS-2026064533 (CASL - Cyber Security Awareness Course for Personal and
-- Businesses).
--
-- 1. name, url_key/url_path (basic-cyber-security-course -> cyber-security-awareness-workshop),
--    cover alt/gallery labels, meta_title/description/keyword.
-- 2. "What's This Course About" and course topics follow the parent (its 2 About paragraphs,
--    with "the CASL ... Course" reworded to "this Cyber Security Awareness Workshop", and its
--    3-topic LSN_DATA outline). ASCII literals, not a parent join (see 1619).
--    Duration 7.5 hrs, Sessions 1 and $350 stay as they are.
-- 3. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 4. Funding block: WSQ-twin link moved off the wsq-cyber-security-awareness-course.html
--    alias (which 301s) onto the parent's bare slug, with the parent's current title.
-- 5. 301s: the product's system rows are renamed in place to the new slug (so the new
--    URL resolves without a rewrite refresh); every old path, bare or category-prefixed,
--    301s one hop to the new BARE slug, and legacy RP rows are flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C506' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064533' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'Cyber Security Awareness Workshop';
SET @old_slug  := 'basic-cyber-security-course';
SET @new_slug  := 'cyber-security-awareness-workshop';

SET @a_name    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_urlkey  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_key');
SET @a_urlpath := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'url_path');
SET @a_mtitle  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_title');
SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
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

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mtitle, 0, @pid, @new_title
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Build cyber resilience in this hands-on Cyber Security Awareness Workshop. Spot malware, phishing and online scams, protect personal and business data, and apply security best practice at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Cyber Security Awareness, Cyber Security Awareness Workshop, Cyber Security Training, Cyber Security, Malware, Phishing, Online Scams, Social Engineering, Data Protection, Password Security, Business Security, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Discover how to fortify your digital world against cyber threats in this Cyber Security Awareness Workshop, designed for both individuals and businesses. Learn the ins and outs of online safety, data protection, and cybersecurity fundamentals, including password management, phishing prevention, and secure browsing techniques. Equip yourself with vital knowledge to protect your personal data, as well as safeguard your business\'s confidential information.</p>\n<p>This course offers practical insights into the latest cyber threats and vulnerabilities, along with hands-on training on implementing effective cybersecurity measures. Whether you are looking to enhance your personal online safety or secure your business infrastructure, this course provides comprehensive strategies and actionable steps to help you become more cyber-resilient. By the end of the course, you\'ll be empowered with the skills and understanding to mitigate cybersecurity risks effectively.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1 - Cyber Security Threats","subsecs":[{"title":"Introduction to Cyber Security","links":[]},{"title":"Malwares - Viruses, Worms, Trojan Horse, Ransomware, Spyware","links":[]},{"title":"Hoaxes and Phishing Scams","links":[]},{"title":"Social Media and Social Engineering Threats","links":[]},{"title":"Mobile and Online Scams","links":[]},{"title":"Wireless Security Threats","links":[]},{"title":"Network and Remote Access Threats","links":[]},{"title":"Cyber Warfare","links":[]}]},{"title":"Topic 2 - Protection Against Cyber Security Threats","subsecs":[{"title":"User ID and Passwords Protection","links":[]},{"title":"Home Computer and Information Protection with Firewalls","links":[]},{"title":"Best Practices Against Malware, Computer Viruses and Worms","links":[]},{"title":"Trojans and Spyware Protection","links":[]},{"title":"Protection from Hoaxes and Phishing","links":[]},{"title":"Mobile Devices and Wireless Protection","links":[]},{"title":"Remote Access Protection with SSL","links":[]},{"title":"Social Media and Online Scams Protection","links":[]}]},{"title":"Topic 3 - Security Management for Businesses","subsecs":[{"title":"Identify Organizations Assets from Cyber Attacks","links":[]},{"title":"Secure Personal Data","links":[]},{"title":"Secure Sockets Layer","links":[]},{"title":"Security Governance","links":[]},{"title":"Business Continuity Planning","links":[]},{"title":"IDS/IPS Systems & Penetration Testing","links":[]}]}] -->\n<p><strong>Topic 1 - Cyber Security Threats</strong></p>\n<p><em>Introduction to Cyber Security</em></p>\n<p><em>Malwares - Viruses, Worms, Trojan Horse, Ransomware, Spyware</em></p>\n<p><em>Hoaxes and Phishing Scams</em></p>\n<p><em>Social Media and Social Engineering Threats</em></p>\n<p><em>Mobile and Online Scams</em></p>\n<p><em>Wireless Security Threats</em></p>\n<p><em>Network and Remote Access Threats</em></p>\n<p><em>Cyber Warfare</em></p>\n<p><strong>Topic 2 - Protection Against Cyber Security Threats</strong></p>\n<p><em>User ID and Passwords Protection</em></p>\n<p><em>Home Computer and Information Protection with Firewalls</em></p>\n<p><em>Best Practices Against Malware, Computer Viruses and Worms</em></p>\n<p><em>Trojans and Spyware Protection</em></p>\n<p><em>Protection from Hoaxes and Phishing</em></p>\n<p><em>Mobile Devices and Wireless Protection</em></p>\n<p><em>Remote Access Protection with SSL</em></p>\n<p><em>Social Media and Online Scams Protection</em></p>\n<p><strong>Topic 3 - Security Management for Businesses</strong></p>\n<p><em>Identify Organizations Assets from Cyber Attacks</em></p>\n<p><em>Secure Personal Data</em></p>\n<p><em>Secure Sockets Layer</em></p>\n<p><em>Security Governance</em></p>\n<p><em>Business Continuity Planning</em></p>\n<p><em>IDS/IPS Systems &amp; Penetration Testing</em></p>\n\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C506-20261001-040120.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C506 - Funding and Grant', 'course_C506_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C506_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C506_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C506_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-cyber-security-awareness-course-for-personal-and-businesses.html" title="CASL - Cyber Security Awareness Course for Personal and Businesses">CASL - Cyber Security Awareness Course for Personal and Businesses</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C506_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c506_old;
CREATE TEMPORARY TABLE tmp_c506_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c506_old
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
  FROM tmp_c506_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c506_old;
