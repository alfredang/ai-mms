-- 223: Remove the 'Why Choose Us?' block (AWS APN / Pearson Vue claim) from the
--      AWS Certification Exam Prep category description (url_key
--      aws-certification-preparation-exam-courses, cat 404 locally). Targeted by
--      url_key for id-drift safety; content-guarded by hex so it no-ops if absent.

UPDATE catalog_category_entity_text t JOIN eav_attribute ea ON ea.attribute_id=t.attribute_id AND ea.attribute_code='description' AND ea.entity_type_id=3 JOIN catalog_category_entity_varchar uk ON uk.entity_id=t.entity_id AND uk.store_id=0 JOIN eav_attribute ea2 ON ea2.attribute_id=uk.attribute_id AND ea2.attribute_code='url_key' AND ea2.entity_type_id=3 SET t.value = REPLACE(t.value, 0x0d0a0d0a3c68323e5768792043686f6f73652055733f3c2f68323e0d0a3c703e576520617265203c7374726f6e673e417574686f7269736564204157532041504e20547261696e696e6720506172746e65723c2f7374726f6e673e20616e64203c7374726f6e673e417574686f72697365642050656172736f6e2056756520546573742043656e7465722e203c2f7374726f6e673e3c2f703e, '') WHERE uk.value='aws-certification-preparation-exam-courses' AND t.store_id=0;
