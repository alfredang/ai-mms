-- C748 ISO 9001:2015 Quality Management System Internal Auditor Course: 2-day non-WSQ twin
-- of TGS-2023039341 (WSQ - ISO 9001 Quality Management System (QMS) Internal Auditor Training).
--
-- "What's This Course About" follows the WSQ parent, written as a literal (see 1619), naming
-- this course instead of the WSQ title; it states no day count. The funding block pointed at
-- the WRONG WSQ course (Fundamentals of ISO 9001, C239's parent) -> repointed at this course's
-- own WSQ twin. Already correct on prod and left alone: course topics (= parent), meta_description
-- (no day count), Duration 15 hrs, Sessions 2, $700, schedule template B13 (= parent's WSQ-B13).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C748' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023039341' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Venture into the world of quality management with our ISO 9001:2015 Quality Management System Internal Auditor Course. This comprehensive course sheds light on the intricacies of the ISO 9001:2015 standard, emphasizing its principles, terminologies, and the methodologies inherent in effective internal auditing. Participants will be equipped with the skills to plan, conduct, report, and follow-up on an internal audit, ensuring their organization remains compliant and continually improves its QMS.</p>\n<p>With a harmonious blend of theory and practical exercises, the course provides insights into the auditor\'s roles and responsibilities, risk-based thinking, and process-based auditing. Learners will leave with a robust understanding of the internal auditing process, ready to bolster their organization\'s adherence to the globally recognized ISO 9001 standards.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_short AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C748 - Funding and Grant', 'course_C748_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C748_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C748_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C748_funding_and_grant');

UPDATE cms_block
   SET content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-iso-9001-quality-management-system-qms-internal-auditor-training.html" title="WSQ - ISO 9001 Quality Management System (QMS) Internal Auditor Training">WSQ - ISO 9001 Quality Management System (QMS) Internal Auditor Training</a></span></p>',
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C748_funding_and_grant';
