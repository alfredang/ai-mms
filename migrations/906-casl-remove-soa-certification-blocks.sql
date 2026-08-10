-- 906: Remove the OpenCerts / SOA bullet from CASL certification blocks.
-- Since 885 the Certification card renders from the per-course cms_block
-- `course_<sku>_certification`, which takes precedence over view.phtml's
-- name-driven CASL fallback — so the historical sdesc cleanups (747/748/883)
-- no longer reach the rendered card. This strips the OpenCerts (Statement of
-- Achievement) bullet from the certification BLOCK of every course named
-- 'CASL - %', covering the newly converted TGS-2026064860 (Financial
-- Analysis for SMEs) and any future CASL block that slips through.
-- Bullet bytes verified on prod: single-line 885 shape, plain spaces.
-- Idempotent; partner-safe (no CASL-named courses on MY/GH).

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

UPDATE cms_block b
  JOIN catalog_product_entity p ON b.identifier = CONCAT('course_', p.sku, '_certification')
  JOIN catalog_product_entity_varchar n ON n.entity_id = p.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
  SET b.content = REPLACE(b.content, '<li><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</li>', ''),
      b.update_time = NOW()
  WHERE n.value LIKE 'CASL - %' AND b.content LIKE '%OpenCerts%';
