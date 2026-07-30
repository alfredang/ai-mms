-- 854: Follow-up to 851 — the trainer bio for TGS-2024045797 quotes the course
-- by its OLD title.
--
-- trainerprofile contains: In "Project Management Professional (PMP) 35 PDU
-- Training," Khoo Yong brings an educator's perspective ... — a direct quote of
-- the course name, so it has to track the rename.
--
-- Note deliberately NOT changed: meta_keyword still lists "35 PDU" as a keyword
-- term. That is still factually true (the course awards 35 PDUs — only the
-- TITLE dropped the token) and it is a real search term learners use.
--
-- The bio uses curly quotes (&ldquo;/&rdquo;) around the title; the REPLACE
-- targets the inner title text only so the entities are untouched.
--
-- Partner-safe: guarded on @e (TGS- SKUs are SG-only); idempotent.

SET @etid := (SELECT entity_type_id FROM eav_entity_type WHERE entity_type_code = 'catalog_product');
SET @e := (SELECT entity_id FROM catalog_product_entity WHERE sku = 'TGS-2024045797' LIMIT 1);
SET @a_tp := (SELECT attribute_id FROM eav_attribute WHERE entity_type_id = @etid AND attribute_code = 'trainerprofile');

UPDATE catalog_product_entity_text
SET value = REPLACE(value,
      'Project Management Professional (PMP) 35 PDU Training',
      'Project Management Professional')
WHERE entity_id = @e AND @e IS NOT NULL AND attribute_id = @a_tp;
