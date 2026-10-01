-- C879 AI Vibe Coding for iOS Mobile Apps Development = the 2-day non-WSQ twin of TGS-2023037545 (WSQ - AI Vibe
-- Coding for iOS Mobile Apps Development). Courseware v1.0 converted from the WSQ v1.2 set
-- (github.com/tertiarycourses/C879-AI-Vibe-Coding-for-iOS-Mobile-Apps-Development).
--
-- 1. "What's This Course About", course topics (5, LSN_DATA) and "Who should attend" copied from the parent
--    (ASCII literals; none states a day count or WSQ). Replaces the old 4-topic Swift/SwiftUI copy whose About
--    opened "This hands-on 2-day course".
-- 2. Prerequisite: same entry requirement; software list now matches the courseware (Xcode, XcodeGen, CMake, Git,
--    an AI coding assistant) on a Mac.
-- 3. meta_description rewritten without the "2-day course" phrase; orphan TEXT-table meta_description deleted.
-- 4. Cover alt / gallery labels: the stale "AI Vibe Coding for Quick iOS Mobile Apps Deployment" -> the course title.
-- 5. Funding block points at the WSQ twin's canonical URL (was the legacy
--    wsq-native-ios-apps-development-with-c-and-vibe-coding.html alias, which 301s there).
-- Name / slug / fee / duration / sessions are already right ($700 / 15 / 2) -> unchanged. Schedule template is
-- switched on prod via the code path, not here.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C879' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023037545' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @title := 'AI Vibe Coding for iOS Mobile Apps Development';

SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_who     := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'whoshouldattend');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

-- ------------------------------------------------------ image labels -----
UPDATE catalog_product_entity_varchar v
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.entity_type_id = 4
   AND a.attribute_code IN ('image_label', 'small_image_label', 'thumbnail_label')
   SET v.value = @title
 WHERE @ok AND v.entity_id = @pid;

UPDATE catalog_product_entity_media_gallery_value gv
  JOIN catalog_product_entity_media_gallery g ON g.value_id = gv.value_id
   SET gv.label = @title
 WHERE @ok AND g.entity_id = @pid;

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Build and ship native iOS apps with AI vibe coding: SwiftUI, an Objective-C++ adapter and a portable C++ core, tested in Xcode and the iOS Simulator, at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;

-- Orphan TEXT-table meta_description shadows the varchar value on render.
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc;

-- ------------------------- About + topics + who should attend from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course equips aspiring developers and IT professionals with the skills to design, develop, test, and deploy modern iOS applications using C++ and AI-powered vibe coding techniques. Participants will learn the complete iOS application development lifecycle, from software design and architecture planning to coding, testing, deployment, and maintenance.</p><p>The course covers core C++ programming concepts, including object-oriented programming, classes, functions, and software modularization, while introducing essential iOS software design principles and user experience considerations. Learners will also explore how AI-assisted development tools can accelerate coding, improve productivity, and enhance software quality through modern vibe coding workflows.</p><p>Through hands-on activities, participants will develop iOS applications, use simulators for testing and debugging, and apply best practices for application validation and performance optimization. The course also introduces the Apple development ecosystem, including application packaging, code signing, App Store requirements, and deployment processes.</p><p>By the end of the course, participants will be able to design and build iOS applications, leverage AI tools to improve development efficiency, test applications using simulators and devices, and successfully publish applications to the Apple App Store. This practical course provides a strong foundation for developers seeking to build professional iOS applications in an AI-augmented software development environment.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Introduction to Native iOS Application Development and Vibe Coding","subsecs":[]},{"title":"Topic 2: C++ Programming Fundamentals for iOS Development","subsecs":[]},{"title":"Topic 3: Native iOS Application Design and Development","subsecs":[]},{"title":"Topic 4: Testing, Debugging, and Assessing iOS Applications","subsecs":[]},{"title":"Topic 5: Application Deployment, Documentation, and App Store Publishing","subsecs":[]}] -->\r\n<p><strong>Topic 1: Introduction to Native iOS Application Development and Vibe Coding</strong></p>\r\n<p><strong>Topic 2: C++ Programming Fundamentals for iOS Development</strong></p>\r\n<p><strong>Topic 3: Native iOS Application Design and Development</strong></p>\r\n<p><strong>Topic 4: Testing, Debugging, and Assessing iOS Applications</strong></p>\r\n<p><strong>Topic 5: Application Deployment, Documentation, and App Store Publishing</strong></p>\r\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_who, 0, @pid, '<ul><li>iOS App Developer</li><li>Mobile Application Developer</li><li>Software Engineer</li><li>C++ Developer</li><li>Full-Stack Developer (extending to mobile)</li><li>Application Developer</li><li>Systems Programmer</li><li>Cross-Platform App Developer</li><li>UI/UX Developer (building iOS interfaces)</li><li>QA / Test Engineer (mobile app testing)</li><li>Mobile Product Manager</li><li>Technical Lead (mobile projects)</li><li>IT Specialist (wanting to learn iOS development)</li><li>Freelance App Developer</li><li>Tech Start-up Founder</li></ul>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------- entry + software/hardware requirement -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<p>Target Age Group: 18-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<p>Download and install the following software on your Mac:</p>\n<ul>\n<li><span style="text-decoration: underline;"><a href="https://developer.apple.com/xcode/" target="_blank">Xcode</a></span> (iOS 17+ SDK) with an iPhone Simulator</li>\n<li><span style="text-decoration: underline;"><a href="https://github.com/yonaskolb/XcodeGen" target="_blank">XcodeGen</a></span> and <span style="text-decoration: underline;"><a href="https://cmake.org/download/" target="_blank">CMake</a></span> (e.g. via Homebrew)</li>\n<li>Git</li>\n<li>An AI coding assistant (Claude, ChatGPT, GitHub Copilot or Cursor &mdash; the free tier is sufficient)</li>\n</ul>\n<p><strong>Hardware:</strong>&nbsp;Mac laptop (Apple silicon recommended) with administrator rights to install software</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_who, @a_prereq) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C879 - Funding and Grant', 'course_C879_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C879_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C879_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C879_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2> <p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-ai-vibe-coding-for-ios-mobile-apps-development.html" title="WSQ - AI Vibe Coding for iOS Mobile Apps Development">WSQ - AI Vibe Coding for iOS Mobile Apps Development</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C879_funding_and_grant';
