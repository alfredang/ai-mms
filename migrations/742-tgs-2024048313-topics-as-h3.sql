-- 742: TGS-2024048313 (WSQ - Native Android Apps Development with Java and
-- Vibe Coding) — outline was <ul><li><strong> (renders as indented bullets);
-- convert to the flush-left h3.course-topic-h3 main-topic shape.
-- Partner-safe: TGS- absent on MY/GH => no-op.

SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024048313');
SET @a_desc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'description');

UPDATE catalog_product_entity_text SET value = CONCAT(
'<h3 class="course-topic-h3">Topic 1: Introduction to Native Android Application Development and Vibe Coding</h3>', '\n',
'<h3 class="course-topic-h3">Topic 2: Java Programming Fundamentals for Android Development</h3>', '\n',
'<h3 class="course-topic-h3">Topic 3: Android Application Design, Object-Oriented Programming, and User Interface Development</h3>', '\n',
'<h3 class="course-topic-h3">Topic 4: Data Management, APIs, Testing, Debugging, and Error Handling in Android Applications</h3>', '\n',
'<h3 class="course-topic-h3">Topic 5: Application Documentation, Performance Optimization, Multi-threading, and Google Play Store Deployment</h3>')
  WHERE entity_id = @e AND attribute_id = @a_desc AND store_id = 0;
