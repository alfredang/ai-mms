-- 927: Remove the OpenCerts / SOA bullet from CASL certification blocks.
-- Same shape as 906/924 — re-shipped as a NEW file because those already ran
-- on prod and an applied migration never re-runs, so the newly converted
-- TGS-2026064177 (CASL - Excel Power Query and Power Pivot) would keep its
-- bullet. The Certification card renders from the per-course cms_block
-- `course_<sku>_certification` (885), which OVERRIDES view.phtml's
-- name-driven CASL suppression — the data edit is what reaches the page.
-- Bullet bytes verified on prod for this course: single-line 885 shape,
-- plain spaces, no CRLF/nbsp variants.
-- Idempotent; partner-safe (no CASL-named courses on MY/GH).

SET @a_name := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = 4 AND attribute_code = 'name');

UPDATE cms_block b
  JOIN catalog_product_entity p ON b.identifier = CONCAT('course_', p.sku, '_certification')
  JOIN catalog_product_entity_varchar n ON n.entity_id = p.entity_id AND n.attribute_id = @a_name AND n.store_id = 0
  SET b.content = REPLACE(b.content, '<li><strong>OpenCerts from SkillsFuture Singapore</strong> - After passing the assessment(s) and achieving at least 75% attendance, participants will receive a OpenCert (aka Statement of Achievement) from SkillsFuture Singapore, certifying that they have achieved the Competency Standard(s) in the above Skills Framework.</li>', ''),
      b.update_time = NOW()
  WHERE n.value LIKE 'CASL - %' AND b.content LIKE '%OpenCerts%';
