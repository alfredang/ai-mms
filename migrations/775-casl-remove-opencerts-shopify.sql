-- 775: Re-run the CASL OpenCerts rule (see 747/748) for the newly converted
-- CASL - Running a Successful eCommerce Store with Shopify (TGS-2026064175).
-- Earlier copies already ran on prod before this conversion, so this
-- name-driven cleanup must ship as a NEW file (edited migrations never
-- re-run). Removes the OpenCerts bullet from the Certification section of
-- every course named 'CASL - %', matching BOTH CRLF and LF line endings.
-- The storefront template rebuilds the Certification card and already
-- suppresses OpenCerts for CASL names, so this is the belt-and-braces data
-- cleanup. Idempotent; partner-safe.

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
