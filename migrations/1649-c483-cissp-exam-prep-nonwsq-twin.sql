-- C483: "ISC2 Information Systems Security Professional (CISSP) Training" -> "CISSP Exam Prep", the
-- 5-day non-WSQ twin of TGS-2024043392 (WSQ - ISC2 Information Systems Security Professional (CISSP)
-- Training).
--
-- 1. name, url_key/url_path (isc2-information-systems-security-professional-cissp-exam-prep ->
--    cissp-exam-prep), cover alt/gallery labels, meta_title/description/keyword.
-- 2. "What's This Course About" and course topics follow the WSQ parent (its 3 About paragraphs,
--    "The ISC2 ... (CISSP) Exam Prep course" -> "The CISSP Exam Prep course", and its 8 topics,
--    LSN_DATA JSON + HTML). The parent's trailing "Exam Voucher" heading (which names an *Autodesk*
--    voucher, a copy-paste error) is NOT carried over. Written as ASCII literals, not a parent join
--    (the parent text carries cp1252 NBSP/en-dash/curly-quote bytes). Duration 37.5 hrs, Sessions 5
--    and $1,800 stay as they are.
-- 3. Cover: re-rendered with the new title and uploaded to R2 (the PNG bakes the title).
-- 4. Funding block: "No funding" now points straight at the WSQ twin's canonical URL (the old link
--    named a retired slug that 301'd there).
-- 5. 301s: the product's system rows are renamed in place to the new slug (so the new URL resolves
--    without a rewrite refresh); every old path, bare or category-prefixed, 301s one hop to the new
--    BARE slug, legacy RP rows and search redirects are flattened onto it.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C483' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2024043392' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @new_title := 'CISSP Exam Prep';
SET @old_slug  := 'isc2-information-systems-security-professional-cissp-exam-prep';
SET @new_slug  := 'cissp-exam-prep';

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
SELECT 4, @a_mdesc, 0, @pid, 'Prepare for the ISC2 CISSP exam in this 5-day CISSP Exam Prep course covering all 8 domains, from security and risk management to software development security, at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'CISSP Exam Prep, CISSP, CISSP Training, CISSP Course, CISSP Exam Preparation, ISC2 CISSP, ISC2 Certification, Certified Information Systems Security Professional, Cybersecurity Certification, Information Security Training, Security and Risk Management, Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>The CISSP Exam Prep course is meticulously designed for professionals seeking to deepen their knowledge and skills in information security. The course begins with a focus on Security and Risk Management, emphasizing professional ethics, security concepts, the legal environment, and secure design principles. Participants will gain a clear understanding of the key aspects of Asset Security, including managing information assets and data security life cycles.</p> <p>Moving into the intricacies of Security Architecture and Engineering, the course covers vulnerabilities assessment, cryptographic systems, and the essentials of cryptanalysis. Communication and Network Security is another critical topic, providing insight into the OSI and TCP/IP models and their application in secure network design. Identity and Access Management (IAM) is thoroughly explored, highlighting the importance of managing identities, access controls, and authentication systems.</p> <p>Additionally, the course emphasizes Security Assessment and Testing, enabling learners to design effective security assessment strategies and analyze organizational security performance. Security Operations is a key module that includes incident management, logging, and monitoring activities, as well as implementing backup and recovery strategies. The final topic, Software Development Security, delves into the vulnerabilities inherent in software systems, malware and ransomware threats, and the implementation of security controls in software development ecosystems. This course ensures that participants are well-prepared for the CISSP exam, equipping them with the knowledge to develop action plans, evaluate technologies, introduce security controls, and address lapses in organizational security standards.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Security and Risk Management","subsecs":[{"title":"Understand, adhere to and Promote Professional Ethics","links":[]},{"title":"Understand and Apply Security Concepts","links":[]},{"title":"Evaluate and Apply Security Concepts","links":[]},{"title":"Legal Environment","links":[]},{"title":"Basic Secure Design Principles","links":[]}]},{"title":"Topic 2: Asset Security","subsecs":[{"title":"Information Assets","links":[]},{"title":"Manage the data security life cycle","links":[]},{"title":"Determine Data security controls and compliance requirements","links":[]}]},{"title":"Topic 3: Security Architecture and Engineering","subsecs":[{"title":"Assess and mitigate the vulnerabilities of Security Architectures, Design and Solution Elements","links":[]},{"title":"Cryptographic Systems","links":[]},{"title":"Hybrid Systems and the Public Key Infrastructure (PKI)","links":[]},{"title":"Cryptographic Systems Hygiene: Operation and Maintenance","links":[]},{"title":"Cryptanalysis - Methods of Cryptanalytic Attacks","links":[]}]},{"title":"Topic 4: Communication and Network Security","subsecs":[{"title":"Open Systems Interconnection (OSI) and Transmission Control Protocol (TCP) over Internet Protocol (TCP/IP) models","links":[]},{"title":"OSI Layer 1 (Physical Layer)","links":[]},{"title":"OSI Layer 2 (Data Link Layer)","links":[]},{"title":"OSI Layer 3 (Network Layer)","links":[]},{"title":"OSI Layer 4 (Transport Layer)","links":[]},{"title":"OSI Layer 5 (Session Layer)","links":[]},{"title":"OSI Layer 6 (Presentation Layer)","links":[]},{"title":"OSI Layer 7 (Application Layer)","links":[]},{"title":"Secure Design Principles in Network Architecture","links":[]},{"title":"Secure Network Components","links":[]},{"title":"Implementing Secure Communications Channels According to Design","links":[]}]},{"title":"Topic 5: Identity and Access Management IAM","subsecs":[{"title":"Manage the Identity and Access Provisioning Lifecycle","links":[]},{"title":"Implement and Manage Access Control Models and Mechanisms","links":[]},{"title":"Managing People and Operations","links":[]},{"title":"Control Physical and Logical Access to Assets","links":[]},{"title":"Manage Identification and Authentication of People, Devices and Services","links":[]},{"title":"Implement Authentication and Authorization Systems","links":[]}]},{"title":"Topic 6: Security Assessment and Testing","subsecs":[{"title":"Design and validate Assessment, Test and Audit Strategies","links":[]},{"title":"Conduct Security Control Assessment","links":[]},{"title":"Collect Security Process Data","links":[]},{"title":"Analyze and report on Organization Performance","links":[]}]},{"title":"Topic 7: Security Operations","subsecs":[{"title":"Conduct Logging and Monitoring Activities","links":[]},{"title":"Perform Change Management","links":[]},{"title":"Basic Incident Response Concepts","links":[]},{"title":"Conduct Incident Management","links":[]},{"title":"Operate and maintain Detective and Preventative Measures","links":[]},{"title":"Implement Backup and Recovery Strategies","links":[]},{"title":"Apply Security Design Principles to Site and Facility Design","links":[]},{"title":"Site and Facility Security Controls","links":[]},{"title":"Personnel Safety and Security Control","links":[]}]},{"title":"Topic 8: Software Development Security","subsecs":[{"title":"Why so many software systems are Unsecure","links":[]},{"title":"Security Weaknesses at the source code level: Why so much software is unsecure","links":[]},{"title":"Why Databases can be unsecure","links":[]},{"title":"Why websites can be unsecure","links":[]},{"title":"Malware, ransomware, and Ransom Attacks: The software perspective","links":[]},{"title":"Baking In Security: Development Management Choices","links":[]},{"title":"Security Controls in Software Development Ecosystems","links":[]},{"title":"Risk Analysis and Mitigation for Software Apps and Systems","links":[]}]}] -->\n<p><strong>Topic 1: Security and Risk Management</strong></p>\n<p><em>Understand, adhere to and Promote Professional Ethics</em></p>\n<p><em>Understand and Apply Security Concepts</em></p>\n<p><em>Evaluate and Apply Security Concepts</em></p>\n<p><em>Legal Environment</em></p>\n<p><em>Basic Secure Design Principles</em></p>\n<p><strong>Topic 2: Asset Security</strong></p>\n<p><em>Information Assets</em></p>\n<p><em>Manage the data security life cycle</em></p>\n<p><em>Determine Data security controls and compliance requirements</em></p>\n<p><strong>Topic 3: Security Architecture and Engineering</strong></p>\n<p><em>Assess and mitigate the vulnerabilities of Security Architectures, Design and Solution Elements</em></p>\n<p><em>Cryptographic Systems</em></p>\n<p><em>Hybrid Systems and the Public Key Infrastructure (PKI)</em></p>\n<p><em>Cryptographic Systems Hygiene: Operation and Maintenance</em></p>\n<p><em>Cryptanalysis - Methods of Cryptanalytic Attacks</em></p>\n<p><strong>Topic 4: Communication and Network Security</strong></p>\n<p><em>Open Systems Interconnection (OSI) and Transmission Control Protocol (TCP) over Internet Protocol (TCP/IP) models</em></p>\n<p><em>OSI Layer 1 (Physical Layer)</em></p>\n<p><em>OSI Layer 2 (Data Link Layer)</em></p>\n<p><em>OSI Layer 3 (Network Layer)</em></p>\n<p><em>OSI Layer 4 (Transport Layer)</em></p>\n<p><em>OSI Layer 5 (Session Layer)</em></p>\n<p><em>OSI Layer 6 (Presentation Layer)</em></p>\n<p><em>OSI Layer 7 (Application Layer)</em></p>\n<p><em>Secure Design Principles in Network Architecture</em></p>\n<p><em>Secure Network Components</em></p>\n<p><em>Implementing Secure Communications Channels According to Design</em></p>\n<p><strong>Topic 5: Identity and Access Management IAM</strong></p>\n<p><em>Manage the Identity and Access Provisioning Lifecycle</em></p>\n<p><em>Implement and Manage Access Control Models and Mechanisms</em></p>\n<p><em>Managing People and Operations</em></p>\n<p><em>Control Physical and Logical Access to Assets</em></p>\n<p><em>Manage Identification and Authentication of People, Devices and Services</em></p>\n<p><em>Implement Authentication and Authorization Systems</em></p>\n<p><strong>Topic 6: Security Assessment and Testing</strong></p>\n<p><em>Design and validate Assessment, Test and Audit Strategies</em></p>\n<p><em>Conduct Security Control Assessment</em></p>\n<p><em>Collect Security Process Data</em></p>\n<p><em>Analyze and report on Organization Performance</em></p>\n<p><strong>Topic 7: Security Operations</strong></p>\n<p><em>Conduct Logging and Monitoring Activities</em></p>\n<p><em>Perform Change Management</em></p>\n<p><em>Basic Incident Response Concepts</em></p>\n<p><em>Conduct Incident Management</em></p>\n<p><em>Operate and maintain Detective and Preventative Measures</em></p>\n<p><em>Implement Backup and Recovery Strategies</em></p>\n<p><em>Apply Security Design Principles to Site and Facility Design</em></p>\n<p><em>Site and Facility Security Controls</em></p>\n<p><em>Personnel Safety and Security Control</em></p>\n<p><strong>Topic 8: Software Development Security</strong></p>\n<p><em>Why so many software systems are Unsecure</em></p>\n<p><em>Security Weaknesses at the source code level: Why so much software is unsecure</em></p>\n<p><em>Why Databases can be unsecure</em></p>\n<p><em>Why websites can be unsecure</em></p>\n<p><em>Malware, ransomware, and Ransom Attacks: The software perspective</em></p>\n<p><em>Baking In Security: Development Management Choices</em></p>\n<p><em>Security Controls in Software Development Ecosystems</em></p>\n<p><em>Risk Analysis and Mitigation for Software Apps and Systems</em></p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey, @a_mdesc) AND store_id <> 0;

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_name, @a_mtitle, @a_mdesc, @a_cover) AND store_id <> 0;

-- -------------------------------------------------------------- cover -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_cover, 0, @pid, 'https://pub-77c0dec029944b0386e40673ce81081f.r2.dev/course-covers/C483-20261001-041855.png'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C483 - Funding and Grant', 'course_C483_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C483_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C483_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C483_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-isc2-information-systems-security-professional-cissp-training.html" title="WSQ - ISC2 Information Systems Security Professional (CISSP) Training">WSQ - ISC2 Information Systems Security Professional (CISSP) Training</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C483_funding_and_grant';

-- ------------------------------------------------------- 301 rewrites ----
-- 1) Remember the product's old system paths (bare + category-prefixed).
DROP TEMPORARY TABLE IF EXISTS tmp_c483_old;
CREATE TEMPORARY TABLE tmp_c483_old (store_id SMALLINT, request_path VARCHAR(255));
INSERT INTO tmp_c483_old
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
  FROM tmp_c483_old o;

DROP TEMPORARY TABLE IF EXISTS tmp_c483_old;

-- 5) On-site search terms that sent people to the old slug.
UPDATE catalogsearch_query
   SET redirect = CONCAT('https://www.tertiarycourses.com.sg/', @new_slug, '.html')
 WHERE @ok AND redirect LIKE CONCAT('%/', @old_slug, '.html');
