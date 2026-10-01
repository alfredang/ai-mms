-- C579 Linux Masterclass = non-WSQ twin of TGS-2022017589
-- (WSQ - Linux Configuration and Shell Scripting), converted to a 2-day course to
-- match its WSQ parent.
--
-- 1. Fee $350 -> $700 (2 days at the standard $350/day), every scope row.
-- 2. Duration tile 7.5 -> 15 hrs; Sessions tile 1 -> 2.
-- 3. "What's This Course About" (`short_description`) copied from the WSQ parent as an
--    ASCII/entity literal, with the parent's course name swapped for this one; any
--    store-scope override is dropped so store 0 renders. The course topics
--    (`description`) already match the parent and are left as they are.
-- 4. Funding block created (C579 had none) and linked to the WSQ twin.
--
-- The schedule template (A02 -> B11, the parent's (SG) WSQ-B11 counterpart) is switched
-- through the code path, not SQL.
-- Every statement joins on the TGS- parent, so partner sites (no parent) are no-ops.
-- Idempotent: re-running writes the same values.

UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity c ON c.entity_id = d.entity_id AND TRIM(c.sku) = 'C579'
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.attribute_code = 'price' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2022017589'
   SET d.value = 700;

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C579'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'duration' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2022017589'
   SET v.value = '15';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C579'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'sessions' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2022017589'
   SET v.value = '2';

INSERT INTO catalog_product_entity_text (entity_type_id, attribute_id, store_id, entity_id, value)
SELECT 4, a.attribute_id, 0, c.entity_id, '<p>Ready to level up your Linux skills? Dive into our comprehensive Linux Masterclass. Whether you\'re an aspiring system admin or a developer looking to automate tasks, this course will arm you with the skills you need. Learn essential Linux commands, system configuration, and how to write effective shell scripts. With a blend of theory and hands-on exercises, you\'ll gain the expertise needed to manage Linux systems efficiently.</p><p>Don\'t just stop at the basics! Our course also ventures into advanced shell scripting techniques and best practices in Linux configuration. Learn to optimize your system, troubleshoot issues, and create complex automation scripts that save time and resources. By the end of this course, you\'ll not only be comfortable navigating the Linux command line but also be able to leverage its powerful capabilities, making you an indispensable asset in any tech-driven environment.</p>'
  FROM catalog_product_entity c
  JOIN eav_attribute a ON a.attribute_code = 'short_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2022017589'
 WHERE TRIM(c.sku) = 'C579'
ON DUPLICATE KEY UPDATE value = VALUES(value);

DELETE t FROM catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C579'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'short_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2022017589'
 WHERE t.store_id <> 0;

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C579 - Funding and Grant', 'course_C579_funding_and_grant', '', NOW(), NOW(), 1
  FROM catalog_product_entity p
 WHERE TRIM(p.sku) = 'TGS-2022017589'
   AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C579_funding_and_grant')
 LIMIT 1;

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
 WHERE b.identifier = 'course_C579_funding_and_grant';

UPDATE cms_block b
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2022017589'
   SET b.content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-linux-configuration-and-shell-scripting.html" title="WSQ - Linux Configuration and Shell Scripting">WSQ - Linux Configuration and Shell Scripting</a></span></p>',
       b.update_time = NOW()
 WHERE b.identifier = 'course_C579_funding_and_grant';
