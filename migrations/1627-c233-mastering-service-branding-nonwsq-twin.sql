-- C233 Mastering Service Branding Strategies to Grow Your Business: 1-day non-WSQ
-- twin of TGS-2025053924 (WSQ - Service Branding Strategies to Elevate Your
-- Business); courseware duplicated from that course.
--
-- 1. "What's This Course About" follows the parent, written as a literal (see 1619),
--    naming this course instead of the parent's "This WSQ Service Branding
--    Strategies to Elevate Your Business". No day count. Course topics (description)
--    already carry the parent's four topics and are left alone; meta_description,
--    Duration 7.5, Sessions 1 and the $350 fee are already correct.
-- 2. Funding block already links the WSQ twin; wording tidied ("cheackout", "Wsq").
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Schedule template: C233 is on A03, the counterpart of (SG) WSQ-A03 - no switch.
-- Post-deploy: flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C233' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2025053924' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- ------------------------------------------------- About from parent -----
INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Mastering Service Branding Strategies to Grow Your Business provides participants with essential knowledge and practical strategies to build a strong service brand. Understand the critical role of service branding in an organization&rsquo;s overall branding strategy and its impact on business performance. Learn how successful service brands create a competitive advantage, enhance customer experience, and drive long-term brand loyalty. Through real-world case studies, explore how companies differentiate themselves through service branding initiatives.</p>\r\n<p>This course also equips participants with frameworks to develop, implement, and evaluate effective service branding strategies. Learn to craft compelling brand communication, create customer-centric experiences, and measure the impact of branding efforts using key performance metrics. By the end of the course, participants will be able to establish strong service branding initiatives that align with business goals and deliver measurable success.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id = @a_short AND store_id <> 0;

-- ------------------------------------------------------ funding block -----
INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C233 - Funding and Grant', 'course_C233_funding_and_grant', '', NOW(), NOW(), 1
  FROM DUAL
 WHERE @ok AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C233_funding_and_grant');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT block_id, 0 FROM cms_block
 WHERE @ok AND identifier = 'course_C233_funding_and_grant'
   AND NOT EXISTS (SELECT 1 FROM cms_block_store s JOIN cms_block b ON b.block_id = s.block_id
                    WHERE b.identifier = 'course_C233_funding_and_grant');

UPDATE cms_block
   SET content = '<p>No funding is available for this course.</p> <p>For WSQ funding, please check out the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-service-branding-strategies-to-elevate-your-business.html" title="WSQ - Service Branding Strategies to Elevate Your Business">WSQ - Service Branding Strategies to Elevate Your Business</a></span></p>',
       is_active = 1,
       update_time = NOW()
 WHERE @ok AND identifier = 'course_C233_funding_and_grant';
