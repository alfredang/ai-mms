-- 735: TGS-2023037545 (WSQ - Native iOS Apps Development with C++ and Vibe
-- Coding) — the What You'll Learn outline was authored as <ul><li><strong>,
-- which the theme renders as INDENTED subtopic-style bullets. Convert to the
-- flush-left main-topic shape (h3.course-topic-h3), matching the other
-- repurposed WSQ courses. Partner-safe: TGS- absent on MY/GH => no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2023037545');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

UPDATE catalog_product_entity_text SET value = CONCAT(
'<h3 class="course-topic-h3">Topic 1: Introduction to Native iOS Application Development and Vibe Coding</h3>', '\n',
'<h3 class="course-topic-h3">Topic 2: C++ Programming Fundamentals for iOS Development</h3>', '\n',
'<h3 class="course-topic-h3">Topic 3: Native iOS Application Design and Development</h3>', '\n',
'<h3 class="course-topic-h3">Topic 4: Testing, Debugging, and Assessing iOS Applications</h3>', '\n',
'<h3 class="course-topic-h3">Topic 5: Application Deployment, Documentation, and App Store Publishing</h3>')
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;
