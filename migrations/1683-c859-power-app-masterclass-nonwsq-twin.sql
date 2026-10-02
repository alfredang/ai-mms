-- C859 Power App Masterclass = the 1-day non-WSQ twin of TGS-2022015539 (WSQ - Applications Integration with
-- Power Apps and Power Automate). The entity still carried the previous Power Apps Studio / Dataverse copy.
-- Courseware v1.0 converted from the WSQ v8.0 set (github.com/tertiarycourses/C859-Power-App-Masterclass).
--
-- 1. "What's This Course About" and course topics copied from the parent (ASCII literals matching prod; "WSQ-endorsed"
--    dropped; neither states a day count).
-- 2. Prerequisite: "Software: TBD" -> the lab requirements (Microsoft 365 account with Power Platform licence, browser).
-- 3. meta_description / meta_keyword rewritten (no WSQ funding claim, no day count); any orphan TEXT-table
--    meta_description that shadows the varchar value is deleted.
-- 4. Funding block created, pointing at the WSQ twin.
-- Name / slug / fee / duration / sessions are already Power App Masterclass / power-app-masterclass / $350 / 7.5 / 1
-- -> unchanged. Schedule template A13 -> A15 (counterpart of the parent's (SG) WSQ-B15) is switched on prod via the
-- code path, not here.
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C859' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2022015539' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_mdesc   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_description');
SET @a_mkey    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'meta_keyword');
SET @a_short   := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc    := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');
SET @a_prereq  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'prerequisite');

-- --------------------------------------------------------- meta data -----
INSERT INTO catalog_product_entity_varchar (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mdesc, 0, @pid, 'Hands-on Power App Masterclass: build Power Apps canvas apps, automate workflows with Power Automate and integrate the two into one working, tested solution at Tertiary Courses Singapore.'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_varchar
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc AND store_id <> 0;

-- Orphan TEXT-table meta_description shadows the varchar value on render.
DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_mdesc;

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_mkey, 0, @pid, 'Power App Masterclass, Power Apps course, Power Automate course, Power Platform training, application integration, canvas apps, custom connector, low-code automation, Power Apps Singapore'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ----------------------------------------- About + topics from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Uncover the potential of application integration and automation with our hands-on course on Power Apps and Power Automate. The course covers the essentials of building customized apps without coding and creating automated workflows that can transform manual processes into streamlined operations. Through hands-on exercises and real-world scenarios, you''ll acquire actionable skills that can significantly enhance business efficiency.</p>\n<p>By the end of this course, you''ll be adept at leveraging Power Apps and Power Automate for practical business solutions. You''ll know how to build apps tailored to specific business needs and automate repetitive tasks, freeing up valuable time and resources. Whether you''re an IT professional, a business analyst, or a manager aiming to optimize business processes, this course will equip you with the skills you need to drive business transformation.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<!-- LSN_DATA: [{"title":"Topic 1: Opportunities for Using Power Platform Apps","subsecs":[{"title":"Identify opportunities to connect various applications","links":[]},{"title":"Perform feasibility study to identify potential Power Platform applications","links":[]},{"title":"Types and features of Power Platform applications","links":[]}]},{"title":"Topic 2: Power Automate","subsecs":[{"title":"Create Power Automate flow to automate business processes","links":[]},{"title":"Test Power Automate flow","links":[]}]},{"title":"Topic 3: Power Apps","subsecs":[{"title":"Create a Power App that support Web API ","links":[]},{"title":"Verify the functionalities of Power App","links":[]}]},{"title":"Topic 4: Integrate Power Apps and Power Automate","subsecs":[{"title":"Identify issues of Power Apps","links":[]},{"title":"Enhance Power Apps with Power Automate","links":[]}]}] -->\n<p><strong>Topic 1: Opportunities for Using Power Platform Apps</strong></p>\n<p><em>Identify opportunities to connect various applications</em></p>\n<p><em>Perform feasibility study to identify potential Power Platform applications</em></p>\n<p><em>Types and features of Power Platform applications</em></p>\n<p><strong>Topic 2: Power Automate</strong></p>\n<p><em>Create Power Automate flow to automate business processes</em></p>\n<p><em>Test Power Automate flow</em></p>\n<p><strong>Topic 3: Power Apps</strong></p>\n<p><em>Create a Power App that support Web API </em></p>\n<p><em>Verify the functionalities of Power App</em></p>\n<p><strong>Topic 4: Integrate Power Apps and Power Automate</strong></p>\n<p><em>Identify issues of Power Apps</em></p>\n<p><em>Enhance Power Apps with Power Automate</em></p>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- ---------------------------------------- software/hardware requirement -----
-- Anchored on '<p>TBD</p>' alone: the stored blob uses CRLF line endings.
UPDATE catalog_product_entity_text
   SET value = REPLACE(value, '<p>TBD</p>',
       '<ul>\n<li>A Microsoft 365 work or school account with a Power Platform licence (a training account is issued in class)</li>\n<li>Microsoft Edge or Google Chrome &mdash; everything runs in the browser, nothing is installed</li>\n</ul>')
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_prereq AND store_id = 0
   AND value LIKE '%<p>TBD</p>%';

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc, @a_mkey) AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C859 - Funding and Grant', 'course_C859_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C859_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C859_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C859_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-applications-integration-with-power-apps-and-power-automate.html" title="WSQ - Applications Integration with Power Apps and Power Automate">WSQ - Applications Integration with Power Apps and Power Automate</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C859_funding_and_grant';
