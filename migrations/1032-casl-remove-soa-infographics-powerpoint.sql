-- 1032: Remove the OpenCerts / SOA bullet from CASL certification blocks.
-- Since 885 the Certification card renders from the per-course cms_block
-- `course_<sku>_certification`, which takes precedence over view.phtml's
-- name-driven CASL fallback — so the historical sdesc cleanups (747/748/883)
-- no longer reach the rendered card. 906 shipped this same sweep but has
-- already applied on prod and never re-runs, so the newly converted
-- TGS-2026064178 (Infographics and Data Visualization with PowerPoint) needs
-- its own copy.
-- Bullet bytes verified on prod 2026-08-15: single-line 885 shape, plain
-- spaces, no CRLF/nbsp variants.
-- Idempotent; partner-safe (no CASL-named courses on MY/GH).

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

UPDATE cms_block b
  JOIN catalog_product_entity p ON b.identifier = CONCAT('course_', p.sku, '_certification')
  JOIN catalog_product_entity_varchar n ON n.entity_id = p.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
  SET b.content = REPLACE(b.content, '<li><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</li>', ''),
      b.update_time = NOW()
  WHERE n.value LIKE 'CASL - %' AND b.content LIKE '%OpenCerts%';
