-- 759: CASL OpenCerts rule — remove the '&nbsp;&nbsp;achieved' bullet
-- variant that 748/755 missed. Some courses (e.g. the newly converted
-- TGS-2026064719 Design Thinking) carry the OpenCerts bullet with a double
-- &nbsp; before 'achieved', so the plain-space patterns in 748/755 were
-- no-ops for them. Same rule, both line-ending shapes, for every course
-- named 'CASL - %'. Idempotent; partner-safe (no CASL-named courses on
-- MY/GH => no rows match).

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity_varchar n ON n.entity_id = t.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
  SET t.value = REPLACE(t.value, '<li>\r\n<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have&nbsp;&nbsp;achieved the Competency Standard(s) in the above Skills Framework.</p>\r\n</li>\r\n', '')
  WHERE t.attribute_id = @a_sdesc AND t.store_id = 0 AND n.value LIKE 'CASL - %';

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity_varchar n ON n.entity_id = t.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
  SET t.value = REPLACE(t.value, '<li>\n<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have&nbsp;&nbsp;achieved the Competency Standard(s) in the above Skills Framework.</p>\n</li>\n', '')
  WHERE t.attribute_id = @a_sdesc AND t.store_id = 0 AND n.value LIKE 'CASL - %';
