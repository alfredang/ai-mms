-- C239 ISO 9001:2015 Quality Management System: 1-day non-WSQ twin of TGS-2023020563
-- (WSQ - Fundamentals of ISO 9001 Quality Management System).
--
-- "What's This Course About" and the course topics follow the WSQ parent, written as
-- literals (see 1619). About names this course instead of the WSQ title and drops the
-- parent's "up to 70% WSQ funding subsidy" clause; neither text states a day count.
-- Already correct on prod and left alone: meta_description (no day count), Duration
-- 7.5 hrs, Sessions 1, $350, and the funding block course_C239_funding_and_grant
-- (points at the WSQ twin).
--
-- SG-only (store guard + TGS- parent must exist) -> no-op on MY/GH. Idempotent.
-- Post-deploy (not doable in SQL): schedule template -> A-series counterpart of the
-- parent's template via the code path, then flat reindex + flush.

SET @sg  := (SELECT COUNT(*) FROM core_store WHERE store_id = 1 AND code = 'singapore');
SET @pid := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'C239' LIMIT 1);
SET @src := (SELECT entity_id FROM catalog_product_entity WHERE TRIM(sku) = 'TGS-2023020563' LIMIT 1);
SET @ok  := (@sg = 1 AND @pid IS NOT NULL AND @src IS NOT NULL);

SET @a_short := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');
SET @a_desc  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_short, 0, @pid, '<p>Embark on a journey to master the<strong> ISO 9001:2015 Quality Management System</strong> (QMS) with our comprehensive course. Designed for professionals seeking to enhance their understanding of quality management principles, this course will guide you through the key elements of the ISO 9001 standard, enabling you to implement and maintain a robust QMS within your organization.</p>\n<p>Explore the core components of ISO 9001, including process approach, risk-based thinking, and continuous improvement. Gain insights into quality management best practices, learn to identify gaps, and develop strategies to ensure customer satisfaction and operational excellence. Equip yourself with the knowledge and skills necessary to create a culture of quality and improve your organization\'s performance. Enroll today and kick-start your ISO 9001 journey.</p>'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, @a_desc, 0, @pid, '<h3 class="course-topic-h3">Topic 1: Overview of ISO 9001 Quality Management System (QMS)</h3>\n<ul>\n<li>Introduction to ISO 9001 and QMS</li>\n<li>Areas of improvement in Quality</li>\n<li>Context of Organization and Leadership</li>\n</ul>\n<h3 class="course-topic-h3">Topic 2: Planning, Support, Operation</h3>\n<ul>\n<li>Planning, Support and Operation quality tools in ISO 9001</li>\n<li>Quality objectives and planning to achieve them</li>\n<li>Monitoring and measuring resources</li>\n</ul>\n<h3 class="course-topic-h3">Topic 3: Performance Evaluation</h3>\n<ul>\n<li>Performance evaluation in ISO9001 QMS</li>\n<li>Monitoring, measurement, analysis and evaluation</li>\n<li>Internal audit and management review</li>\n</ul>\n<h3 class="course-topic-h3">Topic 4: Continual Improvement</h3>\n<ul>\n<li>Improvement in ISO9001 QMS</li>\n<li>Non-conformity and corrective actions</li>\n<li>Continual improvement documentation</li>\n</ul>\n'
  FROM DUAL WHERE @ok
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE FROM catalog_product_entity_text
 WHERE @ok AND entity_id = @pid AND attribute_id IN (@a_short, @a_desc) AND store_id <> 0;
