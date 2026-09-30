-- C148 Google Workspace Masterclass = non-WSQ twin of TGS-2023018988
-- (WSQ - Google Workspace for SMEs - Boosting Efficiency and Collaboration),
-- converted to a 2-day course to match its WSQ parent.
--
-- 1. Fee $350 -> $700 (2 days at the standard $350/day), every scope row.
-- 2. Duration tile 7.5 -> 15 hrs; Sessions tile 1 -> 2.
-- 3. Course topics (`description`, store 0) and "What's This Course About"
--    (`short_description`, store 0) copied verbatim from the WSQ parent — the parent's
--    About carries no WSQ wording and no day count.
-- 4. meta_description drops the "1-day" day count.
-- 5. Funding block created (C148 had none) and linked to the WSQ twin.
--
-- The schedule template is switched through the code path, not SQL.
-- Every statement joins on the TGS- parent, so partner sites (no parent) are no-ops.
-- Idempotent: re-running writes the same values.

UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity c ON c.entity_id = d.entity_id AND TRIM(c.sku) = 'C148'
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.attribute_code = 'price' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2023018988'
   SET d.value = 700;

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C148'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'duration' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2023018988'
   SET v.value = '15';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C148'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'sessions' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2023018988'
   SET v.value = '2';

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C148'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2023018988'
  JOIN catalog_product_entity_text pt ON pt.entity_id = p.entity_id AND pt.attribute_id = t.attribute_id AND pt.store_id = 0
   SET t.value = pt.value
 WHERE t.store_id = 0
   AND LENGTH(pt.value) = CHAR_LENGTH(pt.value)
   AND pt.value NOT LIKE '%WSQ%'
   AND pt.value NOT LIKE '%day%';

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C148'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'short_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2023018988'
  JOIN catalog_product_entity_text pt ON pt.entity_id = p.entity_id AND pt.attribute_id = t.attribute_id AND pt.store_id = 0
   SET t.value = pt.value
 WHERE t.store_id = 0
   AND LENGTH(pt.value) = CHAR_LENGTH(pt.value)
   AND pt.value NOT LIKE '%WSQ%'
   AND pt.value NOT LIKE '%day%';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C148'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'meta_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2023018988'
   SET v.value = 'Master Google Workspace in this hands-on masterclass. Govern Drive content, build Docs, Sheets, Forms and Sites assets, and report Workspace metrics at Tertiary Courses Singapore.';

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C148 - Funding and Grant', 'course_C148_funding_and_grant', '', NOW(), NOW(), 1
  FROM catalog_product_entity p
 WHERE TRIM(p.sku) = 'TGS-2023018988'
   AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C148_funding_and_grant')
 LIMIT 1;

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
 WHERE b.identifier = 'course_C148_funding_and_grant';

UPDATE cms_block b
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2023018988'
   SET b.content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-google-workspace-for-smes-boosting-efficiency-and-collaboration.html" title="WSQ - Google Workspace for SMEs - Boosting Efficiency and Collaboration">WSQ - Google Workspace for SMEs - Boosting Efficiency and Collaboration</a></span></p>',
       b.update_time = NOW()
 WHERE b.identifier = 'course_C148_funding_and_grant';
