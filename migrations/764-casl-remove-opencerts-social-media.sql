-- 764: Re-run the CASL OpenCerts rule (see 747/748/759) for the newly
-- converted CASL - Create Social Media Campaigns with Agentic AI
-- (TGS-2026064473). Earlier copies already ran on prod before this
-- conversion, so this name-driven cleanup ships as a NEW file (edited
-- migrations never re-run). This course's bullet carries a SINGLE &nbsp;
-- before 'achieved' ("they have&nbsp;achieved") — a variant the plain-space
-- (748/755) and double-&nbsp; (759) copies both miss — so that shape is
-- covered here alongside the plain-space one, each in CRLF and LF forms.
-- The storefront template already suppresses OpenCerts for CASL names, so
-- this is the belt-and-braces data cleanup. Idempotent; partner-safe (no
-- CASL-named courses on MY/GH => no rows match).

SET @a_name  := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');
SET @a_sdesc := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'short_description');

-- single-&nbsp; variant, CRLF
UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity_varchar n ON n.entity_id = t.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
  SET t.value = REPLACE(t.value, '<li>\r\n<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have&nbsp;achieved the Competency Standard(s) in the above Skills Framework.</p>\r\n</li>\r\n', '')
  WHERE t.attribute_id = @a_sdesc AND t.store_id = 0 AND n.value LIKE 'CASL - %';

-- single-&nbsp; variant, LF
UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity_varchar n ON n.entity_id = t.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
  SET t.value = REPLACE(t.value, '<li>\n<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have&nbsp;achieved the Competency Standard(s) in the above Skills Framework.</p>\n</li>\n', '')
  WHERE t.attribute_id = @a_sdesc AND t.store_id = 0 AND n.value LIKE 'CASL - %';

-- plain-space variant, CRLF
UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity_varchar n ON n.entity_id = t.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
  SET t.value = REPLACE(t.value, '<li>\r\n<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</p>\r\n</li>\r\n', '')
  WHERE t.attribute_id = @a_sdesc AND t.store_id = 0 AND n.value LIKE 'CASL - %';

-- plain-space variant, LF
UPDATE catalog_product_entity_text t
  JOIN catalog_product_entity_varchar n ON n.entity_id = t.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
  SET t.value = REPLACE(t.value, '<li>\n<p><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</p>\n</li>\n', '')
  WHERE t.attribute_id = @a_sdesc AND t.store_id = 0 AND n.value LIKE 'CASL - %';
