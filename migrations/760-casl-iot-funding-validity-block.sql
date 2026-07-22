-- 760: Funding Validity card for TGS-2026064711 (CASL - Business Innovation
-- with Internet-of-Things (IoT)). New per-course cms_block
-- course_<sku>_funding_validity, rendered by the product view template as a
-- "Funding Validity" card directly after the funding card. Validity window
-- per the new SSG registration: 20 Jul 2026 to 19 Jul 2027.
-- Partner-safe: guarded on the TGS- SKU existing (SG-only).

INSERT INTO cms_block (title, identifier, content, creation_time, update_time, is_active)
SELECT 'Course TGS-2026064711 - Funding Validity', 'course_TGS-2026064711_funding_validity',
       '<p>Funding for this course is valid from <strong>20 Jul 2026</strong> to <strong>19 Jul 2027</strong>. Register and complete the course within this period to qualify for funding support.</p>',
       NOW(), NOW(), 1
FROM DUAL
WHERE EXISTS (SELECT 1 FROM catalog_product_entity WHERE sku = 'TGS-2026064711')
  AND NOT EXISTS (SELECT 1 FROM cms_block WHERE identifier = 'course_TGS-2026064711_funding_validity');

INSERT IGNORE INTO cms_block_store (block_id, store_id)
SELECT b.block_id, 0 FROM cms_block b
WHERE b.identifier = 'course_TGS-2026064711_funding_validity';
