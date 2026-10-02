-- C1150 UIPath RPA Masterclass: non-WSQ twin of TGS-2026064721 (CASL - Robotics Process
-- Automation (RPA) for Beginners). Courseware duplicated from the parent (repo
-- tertiarycourses/C1150-UIPath-RPA-Masterclass); the product page follows it here.
--
-- 1. "What's This Course About" and the 5 course topics copied from the parent (literal upserts at
--    store 0; store overrides removed). Opener "our CASL Robotics Process Automation (RPA) course
--    tailored for beginners" -> "our UIPath RPA Masterclass, tailored for beginners". No day count.
-- 2. Funding block linked straight to the parent's live URL (casl-...). The old /wsq-rpa-course.html
--    link 301s to it.
--
-- Already 2 days / 15 hrs / sessions 2 / $700 - unchanged. Schedule template B03 -> B07 (matching
-- the parent's (SG) WSQ-B07) was switched on prod via the controller on 2026-10-02 (not SQL).
-- SG-only (store guard + parent must exist) -> no-op on MY/GH. Idempotent.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C1150' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2026064721' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Ready to revolutionize the way you work? Dive into our UIPath RPA Masterclass, tailored for beginners. Learn how to automate repetitive and time-consuming tasks with the power of UIPath. You\'ll get hands-on experience in workflow design, UIPath Studio, and automating processes across various software platforms. By mastering these basics, you\'ll gain the skills needed to significantly enhance productivity and operational efficiency.</p>\r\n<p>But we go beyond just the fundamentals. The course delves into more advanced aspects of RPA, such as error handling, debugging, and orchestrating more complex automation sequences. This comprehensive approach ensures you are well-prepared to tackle real-world challenges in workflow automation. Whether you\'re a business professional seeking to optimize processes or a tech enthusiast looking to enter the booming field of RPA, this course sets you on the path to success.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Introduction to RPA","subsecs":[{"title":"What is Robotic Process Automation (RPA)","links":[]},{"title":"Value Proposition of RPA","links":[]},{"title":"Benefits of RPA","links":[]},{"title":"How RPA Work?","links":[]},{"title":"RPA Workflow","links":[]},{"title":"Applications of RPA","links":[]},{"title":"Intelligent Process Automation (IPA)","links":[]},{"title":"Install UIPath Community Edition","links":[]},{"title":"Basic Features of UIPath Studio","links":[]}]},{"title":"Topic 2: RPA Workflows","subsecs":[{"title":"Sequence","links":[]},{"title":"Flowchart","links":[]},{"title":"State Machine Workflow","links":[]},{"title":"Variables and Arguments","links":[]},{"title":"If-Else and Switch Activities","links":[]},{"title":"For Each and Break Activities","links":[]},{"title":"While and Do While Activities","links":[]},{"title":"Construct a Fully Functional RPA Workflow","links":[]}]},{"title":"Topic 3: Automations","subsecs":[{"title":"Website Scraping","links":[]},{"title":"Recording","links":[]},{"title":"UI Automation","links":[]}]},{"title":"Topic 4: Debug and Exception Handling","subsecs":[{"title":"Debug RPA Workflows","links":[]},{"title":"Handle Exceptions","links":[]}]},{"title":"Topic 5: Manage RPA","subsecs":[{"title":"What is UIPath Orchestrator","links":[]},{"title":"Basic Features of Orchestrator","links":[]},{"title":"Deploy and Manage Single and Multiple Bots","links":[]}]}] -->\r\n<p><strong>Topic 1: Introduction to RPA</strong></p>\r\n<p><em>What is Robotic Process Automation (RPA)</em></p>\r\n<p><em>Value Proposition of RPA</em></p>\r\n<p><em>Benefits of RPA</em></p>\r\n<p><em>How RPA Work?</em></p>\r\n<p><em>RPA Workflow</em></p>\r\n<p><em>Applications of RPA</em></p>\r\n<p><em>Intelligent Process Automation (IPA)</em></p>\r\n<p><em>Install UIPath Community Edition</em></p>\r\n<p><em>Basic Features of UIPath Studio</em></p>\r\n<p><strong>Topic 2: RPA Workflows</strong></p>\r\n<p><em>Sequence</em></p>\r\n<p><em>Flowchart</em></p>\r\n<p><em>State Machine Workflow</em></p>\r\n<p><em>Variables and Arguments</em></p>\r\n<p><em>If-Else and Switch Activities</em></p>\r\n<p><em>For Each and Break Activities</em></p>\r\n<p><em>While and Do While Activities</em></p>\r\n<p><em>Construct a Fully Functional RPA Workflow</em></p>\r\n<p><strong>Topic 3: Automations</strong></p>\r\n<p><em>Website Scraping</em></p>\r\n<p><em>Recording</em></p>\r\n<p><em>UI Automation</em></p>\r\n<p><strong>Topic 4: Debug and Exception Handling</strong></p>\r\n<p><em>Debug RPA Workflows</em></p>\r\n<p><em>Handle Exceptions</em></p>\r\n<p><strong>Topic 5: Manage RPA</strong></p>\r\n<p><em>What is UIPath Orchestrator</em></p>\r\n<p><em>Basic Features of Orchestrator</em></p>\r\n<p><em>Deploy and Manage Single and Multiple Bots</em></p>\r\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;

UPDATE cms_block
   SET content = '<p>No funding is available for this course</p>\r\n<p>For funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-robotics-process-automation-rpa-for-beginners.html" title="CASL - Robotics Process Automation (RPA) for Beginners">CASL - Robotics Process Automation (RPA) for Beginners</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C1150_funding_and_grant';
