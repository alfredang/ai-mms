-- 748: Fix 747 — the CASL courses' Certification markup uses CRLF (\r\n)
-- line endings (legacy content), so 747's LF-only REPLACE was a no-op.
-- Remove the OpenCerts bullet matching BOTH line-ending shapes, for every
-- course named 'CASL - %'. Idempotent; partner-safe.

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity_varchar n ON n.entity_id = t.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
  SET t.value = REPLACE(t.value, '<li>\r\n<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</p>\r\n</li>\r\n', '')
  WHERE t.attribute_id = @a_sdesc AND t.store_id = 0 AND n.value LIKE 'CASL - %';

UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity_varchar n ON n.entity_id = t.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
  SET t.value = REPLACE(t.value, '<li>\n<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</p>\n</li>\n', '')
  WHERE t.attribute_id = @a_sdesc AND t.store_id = 0 AND n.value LIKE 'CASL - %';
