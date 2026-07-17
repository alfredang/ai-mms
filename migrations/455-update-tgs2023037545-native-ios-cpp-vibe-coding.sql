-- Update WSQ course TGS-2023037545 from "WSQ - Learn C++ Fundamentals with
-- AI Assisted Tools and Vibe Coding" to "WSQ - Native iOS Apps Development
-- with C++ and Vibe Coding": name, topics (description), overview
-- (short_description), meta title/description/keywords, url_key, plus a
-- custom 301 from the old URL so external links (MySkillsFuture, ads) keep
-- working. Learning outcomes block unchanged (new LOs are identical).
-- Partner-safe: TGS- SKUs exist only on SG, so @e is NULL on MY/GH and every
-- statement is a no-op. Store scope 0; per-store overrides of the rewritten
-- attributes are cleared. Idempotent. No content line ends in a semicolon.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku='TGS-2023037545');
SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='name');
SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='description');
SET @a_mt    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_title');
SET @a_md    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_description');
SET @a_mk    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='meta_keyword');
SET @a_url   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id=4 AND attribute_code='url_key');

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_name, 0, @e, 'WSQ - Native iOS Apps Development with C++ and Vibe Coding' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @e, '<p>This course equips aspiring developers and IT professionals with the skills to design, develop, test, and deploy modern iOS applications using C++ and AI-powered vibe coding techniques. Participants will learn the complete iOS application development lifecycle, from software design and architecture planning to coding, testing, deployment, and maintenance.</p>
<p>The course covers core C++ programming concepts, including object-oriented programming, classes, functions, and software modularization, while introducing essential iOS software design principles and user experience considerations. Learners will also explore how AI-assisted development tools can accelerate coding, improve productivity, and enhance software quality through modern vibe coding workflows.</p>
<p>Through hands-on activities, participants will develop iOS applications, use simulators for testing and debugging, and apply best practices for application validation and performance optimization. The course also introduces the Apple development ecosystem, including application packaging, code signing, App Store requirements, and deployment processes.</p>
<p>By the end of the course, participants will be able to design and build iOS applications, leverage AI tools to improve development efficiency, test applications using simulators and devices, and successfully publish applications to the Apple App Store. This practical course provides a strong foundation for developers seeking to build professional iOS applications in an AI-augmented software development environment.</p>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @e, '<ul>
<li><strong>Topic 1: Introduction to Native iOS Application Development and Vibe Coding</strong></li>
<li><strong>Topic 2: C++ Programming Fundamentals for iOS Development</strong></li>
<li><strong>Topic 3: Native iOS Application Design and Development</strong></li>
<li><strong>Topic 4: Testing, Debugging, and Assessing iOS Applications</strong></li>
<li><strong>Topic 5: Application Deployment, Documentation, and App Store Publishing</strong></li>
</ul>' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mt, 0, @e, 'WSQ Native iOS Apps Development with C++ and Vibe Coding | Tertiary Courses Singapore' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_md, 0, @e, 'Design, build, test and publish native iOS apps with C++ and AI-powered vibe coding. Learn the full iOS development lifecycle up to App Store release. Enjoy up to 70% WSQ funding subsidy.' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mk, 0, @e, 'WSQ iOS development course, native iOS apps C++, vibe coding Singapore, iOS app development training, AI assisted coding, App Store publishing, iOS testing debugging simulators, WSQ funded IT course, C++ programming iOS' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_url, 0, @e, 'wsq-native-ios-apps-development-with-c-and-vibe-coding' FROM DUAL WHERE @e IS NOT NULL
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
WHERE @e IS NOT NULL AND entity_id=@e AND store_id<>0 AND attribute_id IN (@a_name, @a_mt, @a_md, @a_url);
DELETE FROM catalog_product_entity_text
WHERE @e IS NOT NULL AND entity_id=@e AND store_id<>0 AND attribute_id IN (@a_short, @a_desc, @a_mk);

-- Custom (is_system=0) 301 so the old URL keeps resolving after the
-- catalog_url reindex replaces the system rewrite. Survives reindexes.
INSERT IGNORE INTO core_url_rewrite (store_id, id_path, request_path, target_path, is_system, options, description)
SELECT s.store_id, 'custom/tgs-2023037545-ios-rename',
       'wsq-learn-c-fundamentals-with-ai-assisted-tools-and-vibe-coding.html',
       'wsq-native-ios-apps-development-with-c-and-vibe-coding.html',
       0, 'RP', 'TGS-2023037545 rename to Native iOS Apps Development with C++ and Vibe Coding'
FROM core_store s WHERE s.store_id > 0 AND @e IS NOT NULL;
