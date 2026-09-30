-- C182 Data Analytics with R = non-WSQ twin of TGS-2026064475
-- (CASL - Data Analytics and Visualization with R), converted to a 2-day course
-- to match its funded parent (courseware duplicated from that course).
--
-- 1. Fee $350 -> $700 (2 days at the standard $350/day), every scope row.
-- 2. Duration tile 7.5 -> 15 hrs; Sessions tile 1 -> 2.
-- 3. Course topics (`description`, store 0) copied verbatim from the parent.
-- 4. "What's This Course About" (`short_description`, store 0) copied from the
--    parent with its "CASL-endorsed course in Data Analytics and Visualization
--    with R" wording replaced. Guarded: nothing is written if the result would
--    still mention WSQ/CASL or a day count.
-- 5. meta_description drops the "1-day" day count.
-- 6. Funding block created (C182 had none) and linked to the funded CASL twin.
--
-- The schedule template (A13 -> B01, the counterpart of the parent's
-- (SG) WSQ-B01) is switched through the code path, not SQL.
-- Every statement joins on the TGS- parent, so partner sites (no parent) are no-ops.
-- Idempotent: re-running writes the same values.

UPDATE catalog_product_entity_decimal d
  JOIN catalog_product_entity c ON c.entity_id = d.entity_id AND TRIM(c.sku) = 'C182'
  JOIN eav_attribute a ON a.attribute_id = d.attribute_id AND a.attribute_code = 'price' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026064475'
   SET d.value = 700;

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C182'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'duration' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026064475'
   SET v.value = '15';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C182'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'sessions' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026064475'
   SET v.value = '2';

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C182'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026064475'
  JOIN catalog_product_entity_text pt ON pt.entity_id = p.entity_id AND pt.attribute_id = t.attribute_id AND pt.store_id = 0
   SET t.value = pt.value
 WHERE t.store_id = 0
   AND LENGTH(pt.value) = CHAR_LENGTH(pt.value)
   AND pt.value NOT LIKE '%WSQ%'
   AND pt.value NOT LIKE '%CASL%'
   AND pt.value NOT LIKE '%Assessment%'
   AND pt.value NOT LIKE '%-day%'
   AND pt.value NOT LIKE '%two-day%'
   AND pt.value NOT LIKE '% days%';

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C182'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'short_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026064475'
  JOIN catalog_product_entity_text pt ON pt.entity_id = p.entity_id AND pt.attribute_id = t.attribute_id AND pt.store_id = 0
   SET t.value = REPLACE(pt.value, 'our CASL-endorsed course in Data Analytics and Visualization with R', 'our hands-on Data Analytics with R course')
 WHERE t.store_id = 0
   AND LENGTH(pt.value) = CHAR_LENGTH(pt.value)
   AND REPLACE(pt.value, 'our CASL-endorsed course in Data Analytics and Visualization with R', '') NOT LIKE '%CASL%'
   AND pt.value NOT LIKE '%WSQ%'
   AND pt.value NOT LIKE '%-day%'
   AND pt.value NOT LIKE '%two-day%'
   AND pt.value NOT LIKE '% days%'
   AND pt.value NOT LIKE '%16 hours%';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C182'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'meta_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026064475'
   SET v.value = 'Analyse data with R. Prepare, summarise, model and visualise research data with the tidyverse and ggplot2 in this hands-on course at Tertiary Courses Singapore.';

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course C182 - Funding and Grant', 'course_C182_funding_and_grant', '', NOW(), NOW(), 1
  FROM catalog_product_entity p
 WHERE TRIM(p.sku) = 'TGS-2026064475'
   AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_C182_funding_and_grant')
 LIMIT 1;

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
 WHERE b.identifier = 'course_C182_funding_and_grant';

UPDATE cms_block b
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2026064475'
   SET b.content = '<h2>Funding and Grant Applications</h2>\r\n<p>No funding is available for this course</p>\r\n<p>For CASL funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/casl-data-analytics-and-visualization-with-r.html" title="CASL - Data Analytics and Visualization with R">CASL - Data Analytics and Visualization with R</a></span></p>',
       b.update_time = NOW()
 WHERE b.identifier = 'course_C182_funding_and_grant';
