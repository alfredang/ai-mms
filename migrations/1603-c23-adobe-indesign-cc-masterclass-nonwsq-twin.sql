-- C23 Adobe InDesign CC Masterclass = non-WSQ twin of TGS-2021007827
-- (WSQ - Creating Stunning Print and Digital Publications with InDesign).
--
-- 1. Course topics (`description`, store 0) copied verbatim from the WSQ parent.
-- 2. "What's This Course About" (`short_description`, store 0) copied from the parent,
--    with its one WSQ-branded opening phrase swapped for the C23 title — a non-WSQ page
--    carries no WSQ wording, and the copy states no day count.
-- 3. meta_description drops the "1-day" day count.
-- 4. Funding block links straight to the canonical WSQ twin page (the old slug 301'd).
--
-- Every statement joins on the parent, so partner sites (no TGS- parent) are no-ops.
-- Idempotent: re-running rewrites the same values.

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C23'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2021007827'
  JOIN catalog_product_entity_text pt ON pt.entity_id = p.entity_id AND pt.attribute_id = t.attribute_id AND pt.store_id = 0
   SET t.value = pt.value
 WHERE t.store_id = 0
   AND LENGTH(pt.value) = CHAR_LENGTH(pt.value);

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity c ON c.entity_id = t.entity_id AND TRIM(c.sku) = 'C23'
  JOIN eav_attribute a ON a.attribute_id = t.attribute_id AND a.attribute_code = 'short_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2021007827'
  JOIN catalog_product_entity_text pt ON pt.entity_id = p.entity_id AND pt.attribute_id = t.attribute_id AND pt.store_id = 0
   SET t.value = REPLACE(pt.value,
         'Embark on a transformative journey with WSQ''s Digital Drawing Layout Production Using InDesign course.',
         'Embark on a transformative journey with the Adobe InDesign CC Masterclass.')
 WHERE t.store_id = 0
   AND LENGTH(pt.value) = CHAR_LENGTH(pt.value)
   AND REPLACE(pt.value,
         'Embark on a transformative journey with WSQ''s Digital Drawing Layout Production Using InDesign course.',
         'Embark on a transformative journey with the Adobe InDesign CC Masterclass.') NOT LIKE '%WSQ%';

UPDATE catalog_product_entity_varchar v
  JOIN catalog_product_entity c ON c.entity_id = v.entity_id AND TRIM(c.sku) = 'C23'
  JOIN eav_attribute a ON a.attribute_id = v.attribute_id AND a.attribute_code = 'meta_description' AND a.entity_type_id = 4
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2021007827'
   SET v.value = 'Master professional page layout in this hands-on Adobe InDesign CC Masterclass. Design documents, style text, build tables and export for print and digital at Tertiary Courses Singapore.';

UPDATE cms_block b
  JOIN catalog_product_entity p ON TRIM(p.sku) = 'TGS-2021007827'
   SET b.content = '<p class="p1">No funding is available for this course.</p>\r\n<p>For WSQ funding, please checkout the details at&nbsp;<span style="text-decoration: underline;"><a href="https://www.tertiarycourses.com.sg/wsq-creating-stunning-print-and-digital-publications-with-indesign.html" title="WSQ - Creating Stunning Print and Digital Publications with InDesign">WSQ - Creating Stunning Print and Digital Publications with InDesign</a></span></p>'
 WHERE b.identifier = 'course_C23_funding_and_grant';
