-- C1063 Power Automate Masterclass = the 2-day non-WSQ twin of TGS-2023040472 (WSQ - Hands On Power Automate
-- Desktop RPA for Work Process Automation, 3 days). Courseware v1.0 converted from the WSQ v7.0 set — all 6 topics and
-- 14 labs compressed into two days (github.com/tertiarycourses/C1063-Power-Automate-Masterclass).
--
-- 1. Course fee $350 -> $700 (every scope row), Duration 7.5 -> 15 hrs, Sessions 1 -> 2 (was a 1-day course).
-- 2. "What's This Course About" copied from the parent (its "WSQ <parent title>" opener names this course instead);
--    course topics copied from the parent's LSN_DATA (same 6 topics; Topic 1's truncated "...and Power" completed to
--    "...and Power Automate" as in the courseware). No day count, no WSQ wording. Store-scope overrides removed.
-- 3. meta_description rewritten in ASCII (the old one carried a mojibake byte); no day count.
-- 4. Prerequisite: software was "TBD" -> the courseware's tools; hardware line had mojibake bytes.
-- 5. Funding block course_C1063_funding_and_grant (did not exist) created, store 0, house wording pointing at the
--    WSQ twin https://www.tertiarycourses.com.sg/wsq-hands-on-power-automate-desktop-rpa-for-work-process-automation.html
--    (returns 200).
-- Name / slug unchanged. Schedule template A18 -> B09 is a code path (CoursesaveController), not SQL.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: price + flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1063' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023040472' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_price  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'price');
SET @a_dur    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'duration');
SET @a_sess   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'sessions');
SET @a_meta   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_short  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_prereq := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

-- ------------------------------------------------------------ fee / duration / sessions -----
INSERT INTO catalog_product_entity_decimal (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_price, 0, @pid, 700 FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
UPDATE catalog_product_entity_decimal SET value = 700
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_price;

INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_dur, 0, @pid, '15' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_sess, 0, @pid, '2' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_meta, 0, @pid, 'Master robotic process automation in this hands-on Power Automate Masterclass - build desktop flows, cloud flows, AI Builder models and custom connectors, then deploy them securely.' FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);
DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_dur, @a_sess, @a_meta) AND store_id <> 0;

-- ------------------------------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>This course, Power Automate Masterclass, equips learners with practical skills to identify automation opportunities across devices, applications, and databases. Through hands-on training, participants will gain experience in using Power Automate Desktop to design, test, and implement robotic process automation workflows. Learners will understand how to evaluate feasibility, troubleshoot integration issues, and optimize automation using real-time data and APIs.</p> <p>The course covers core topics including automation fundamentals, integrating advanced logic, leveraging different technologies within Power Automate, and building secure custom connectors. By the end of the course, learners will be equipped to enhance digital transformation in their workplace by automating repetitive tasks, increasing efficiency, and resolving technical compatibility issues in automation systems.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Automate processes with Robotic Process Automation and Power Automate","subsecs":[]},{"title":"Topic 2: Get started with Power Automate for desktop","subsecs":[]},{"title":"Topic 3: Work with different technologies in Power Automate for desktop","subsecs":[]},{"title":"Topic 4: Implement advanced logic in Power Automate for desktop","subsecs":[]},{"title":"Topic 5: Build expertise with Power Automate for desktop","subsecs":[]},{"title":"Topic 6: Custom Connectors and Security","subsecs":[]}] -->\n<p><strong>Topic 1: Automate processes with Robotic Process Automation and Power Automate</strong></p>\n<p><strong>Topic 2: Get started with Power Automate for desktop</strong></p>\n<p><strong>Topic 3: Work with different technologies in Power Automate for desktop</strong></p>\n<p><strong>Topic 4: Implement advanced logic in Power Automate for desktop</strong></p>\n<p><strong>Topic 5: Build expertise with Power Automate for desktop</strong></p>\n<p><strong>Topic 6: Custom Connectors and Security</strong></p>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

-- ------------------------------------------- entry + software/hardware requirement -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_prereq, 0, @pid, '<h2>Promotion Code</h2>\n<p>Your will get 10% discount voucher for 2nd course onwards if you write us a <span style="text-decoration: underline;"><a href="https://g.page/r/CeH-OtN8J4r9EB0/review" target="_blank">Google review</a>.</span></p>\n<h2>Minimum Entry Requirement</h2>\n<p>Knowledge and Skills</p>\n<ul>\n<li>Able to operate using computer functions</li>\n<li>Minimum 3 GCE &lsquo;O&rsquo; Levels Passes including English or WPL Level 5 (Average of Reading, Listening, Speaking &amp; Writing Scores)</li>\n</ul>\n<p>Attitude</p>\n<ul>\n<li>Positive Learning Attitude</li>\n<li>Enthusiastic Learner</li>\n</ul>\n<p>Experience</p>\n<ul>\n<li>Minimum of 1 year of working experience.</li>\n</ul>\n<p>Target Age Group: 18-65 years old</p>\n<h2>Minimum Software/Hardware Requirement</h2>\n<p><strong>Software:</strong></p>\n<ul>\n<li>A Microsoft 365 / Power Platform developer or trial tenant (free sign-up) with a Dataverse database</li>\n<li>Power Automate for desktop, installed and signed in, plus the Power Automate browser extension for Edge or Chrome</li>\n<li>Microsoft Excel and Outlook</li>\n</ul>\n<p><strong>Hardware:</strong>&nbsp;Windows 10/11 laptop. Power Automate for desktop is Windows-only - Mac users need a Windows virtual machine or a cloud Windows PC.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_prereq AND store_id <> 0;

-- ------------------------------------------------------------- funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C1063 - Funding and Grant', 'course_C1063_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C1063_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C1063_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C1063_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2> <p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-hands-on-power-automate-desktop-rpa-for-work-process-automation.html" title="WSQ - Hands On Power Automate Desktop RPA for Work Process Automation">WSQ - Hands On Power Automate Desktop RPA for Work Process Automation</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C1063_funding_and_grant';
