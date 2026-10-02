-- C882 Quantum Computing Fundamentals for Beginners = the 2-day non-WSQ twin of TGS-2022017591 (WSQ - Quantum
-- Computing for Beginners). Courseware v1.0 converted from the WSQ v11.0 set
-- (github.com/tertiarycourses/C882-Quantum-Computing-Fundamentals-for-Beginners).
--
-- 1. "What's This Course About" copied from the parent (its "Our WSQ ... course" sentence names this course
--    instead); course topics copied in the parent's LSN_DATA form (same 4 topics / 8 sub-topics as before).
--    ASCII literals, no day count, no WSQ wording. Store-scope overrides of both are removed.
-- 2. Prerequisite: software list now matches the courseware - browser-only IBM Quantum Composer labs and a free
--    IBM Quantum account (was "Python"). Entry requirement unchanged.
-- 3. Funding block: house wording, link label now names the WSQ twin (was the legacy "NICF ..." label);
--    target https://www.tertiarycourses.com.sg/wsq-quantum-computing-for-beginners.html returns 200.
-- Name / slug / fee / duration / sessions / meta / image labels are already right ($700 / 15 / 2) -> unchanged.
-- Who-should-attend already equals the parent's. Schedule template B11 -> B05 (parent is on (SG) WSQ-B05) is a
-- code path (CoursesaveController::switchScheduleTemplateAction), not SQL - done separately on prod.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C882' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2022017591' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

-- ------------------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Embark on an exciting journey into the revolutionary field of quantum computing. Our Quantum Computing Fundamentals for Beginners course equips you with the foundational knowledge you''ll need to understand this complex yet fascinating domain. From quantum bits (qubits) and quantum algorithms to quantum mechanics, you''ll gain the skills to comprehend the fundamental theories that are reshaping the world of computing.</p>\n<p>Whether you are a seasoned IT professional or a computing enthusiast, this course is designed to make the subject of quantum computing accessible. You''ll delve into practical applications and real-world scenarios, demystifying the complexity of quantum systems. By the end of the course, you will have a strong grasp of quantum computing concepts, positioning you at the forefront of this emerging field.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Introduction to Quantum Computing","subsecs":[{"title":"Key Principles of Quantum Computing","links":[]},{"title":"Quantum Computing Platforms","links":[]}]},{"title":"Topic 2: Quantum States and Gates","subsecs":[{"title":"Quantum State Vector Representations","links":[]},{"title":"Quantum Circuits and Quantum Gates","links":[]}]},{"title":"Topic 3: Quantum Algorithms","subsecs":[{"title":"Coding Quantum Algorithms","links":[]},{"title":"Testing Quantum Algorithms","links":[]}]},{"title":"Topic 4: Quantum Computing Applications","subsecs":[{"title":"Introduction to Quantum Error Correction","links":[]},{"title":"Introduction to Quantum Machine Learning","links":[]}]}] -->\n<p><strong>Topic 1: Introduction to Quantum Computing</strong></p>\n<p><em>Key Principles of Quantum Computing</em></p>\n<p><em>Quantum Computing Platforms</em></p>\n<p><strong>Topic 2: Quantum States and Gates</strong></p>\n<p><em>Quantum State Vector Representations</em></p>\n<p><em>Quantum Circuits and Quantum Gates</em></p>\n<p><strong>Topic 3: Quantum Algorithms</strong></p>\n<p><em>Coding Quantum Algorithms</em></p>\n<p><em>Testing Quantum Algorithms</em></p>\n<p><strong>Topic 4: Quantum Computing Applications</strong></p>\n<p><em>Introduction to Quantum Error Correction</em></p>\n<p><em>Introduction to Quantum Machine Learning</em></p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

-- ------------------------------------------- entry + software/hardware requirement -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<p>Target Age Group: 18-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<ul>\n<li>No installation needed - every lab runs in the browser on <span style="text-decoration: underline;"><a href="https://quantum.cloud.ibm.com/composer" target="_blank">IBM Quantum Composer</a></span></li>\n<li>A free <span style="text-decoration: underline;"><a href="https://quantum.ibm.com/" target="_blank">IBM Quantum account</a></span> and a modern web browser (Chrome, Edge, Firefox or Safari)</li>\n</ul>\n<p><strong>Hardware:</strong>&nbsp;Window or Mac Laptops</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_prereq AND store_id <> 0;

-- ------------------------------------------------------------- funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C882 - Funding and Grant', 'course_C882_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C882_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C882_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C882_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2> <p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-quantum-computing-for-beginners.html" title="WSQ - Quantum Computing for Beginners">WSQ - Quantum Computing for Beginners</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C882_funding_and_grant';
